//===-- ObjectFileXCOFF.cpp
//-------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "ObjectFileXCOFF.h"

#include <algorithm>
#include <cassert>
#include <cstring>
#include <unordered_map>

#include "lldb/Core/Module.h"
#include "lldb/Core/ModuleSpec.h"
#include "lldb/Core/PluginManager.h"
#include "lldb/Core/Progress.h"
#include "lldb/Core/Section.h"
#include "lldb/Host/FileSystem.h"
#include "lldb/Symbol/SymbolContext.h"
#include "lldb/Target/Process.h"
#include "lldb/Target/Target.h"
#include "lldb/Utility/ArchSpec.h"
#include "lldb/Utility/DataBufferHeap.h"
#include "lldb/Utility/FileSpecList.h"
#include "lldb/Utility/LLDBLog.h"
#include "lldb/Utility/Log.h"
#include "lldb/Utility/RangeMap.h"
#include "lldb/Utility/Status.h"
#include "lldb/Utility/Stream.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/BinaryFormat/XCOFF.h"
#include "llvm/Object/XCOFFObjectFile.h"
#include "llvm/Support/MemoryBuffer.h"

using namespace llvm;
using namespace lldb;
using namespace lldb_private;

LLDB_PLUGIN_DEFINE(ObjectFileXCOFF)

// FIXME: target 64bit at this moment.

// Static methods.
void ObjectFileXCOFF::Initialize() {
  PluginManager::RegisterPlugin(GetPluginNameStatic(),
                                GetPluginDescriptionStatic(), CreateInstance,
                                CreateMemoryInstance, GetModuleSpecifications);
}

void ObjectFileXCOFF::Terminate() {
  PluginManager::UnregisterPlugin(CreateInstance);
}

ObjectFile *ObjectFileXCOFF::CreateInstance(const lldb::ModuleSP &module_sp,
                                            DataBufferSP data_sp,
                                            lldb::offset_t data_offset,
                                            const lldb_private::FileSpec *file,
                                            lldb::offset_t file_offset,
                                            lldb::offset_t length) {
  if (!data_sp) {
    data_sp = MapFileData(*file, length, file_offset);
    if (!data_sp)
      return nullptr;
    data_offset = 0;
  }
  if (!ObjectFileXCOFF::MagicBytesMatch(data_sp, data_offset, length))
    return nullptr;
  // Update the data to contain the entire file if it doesn't already
  if (data_sp->GetByteSize() < length) {
    data_sp = MapFileData(*file, length, file_offset);
    if (!data_sp)
      return nullptr;
    data_offset = 0;
  }
  auto objfile_up = std::make_unique<ObjectFileXCOFF>(
      module_sp, data_sp, data_offset, file, file_offset, length);
  if (!objfile_up)
    return nullptr;

  return objfile_up.release();
}

ObjectFile *ObjectFileXCOFF::CreateMemoryInstance(
    const lldb::ModuleSP &module_sp, WritableDataBufferSP data_sp,
    const lldb::ProcessSP &process_sp, lldb::addr_t header_addr) {
  return nullptr;
}

size_t ObjectFileXCOFF::GetModuleSpecifications(
    const lldb_private::FileSpec &file, lldb::DataBufferSP &data_sp,
    lldb::offset_t data_offset, lldb::offset_t file_offset,
    lldb::offset_t length, lldb_private::ModuleSpecList &specs) {
  const size_t initial_count = specs.GetSize();

  if (ObjectFileXCOFF::MagicBytesMatch(data_sp, 0, data_sp->GetByteSize())) {
    ArchSpec arch_spec =
        ArchSpec(eArchTypeXCOFF, XCOFF::TCPU_PPC64, LLDB_INVALID_CPUTYPE);
    ModuleSpec spec(file, arch_spec);
    spec.GetArchitecture().SetArchitecture(eArchTypeXCOFF, XCOFF::TCPU_PPC64,
                                           LLDB_INVALID_CPUTYPE,
                                           llvm::Triple::AIX);
    specs.Append(spec);
  }
  return specs.GetSize() - initial_count;
}

static uint32_t XCOFFHeaderSizeFromMagic(uint32_t magic) {
  switch (magic) {
    /* TODO: 32bit not supported yet
    case XCOFF::XCOFF32:
      return sizeof(struct llvm::object::XCOFFFileHeader32);
    */

  case XCOFF::XCOFF64:
    return sizeof(struct llvm::object::XCOFFFileHeader64);
    break;

  default:
    break;
  }
  return 0;
}

bool ObjectFileXCOFF::MagicBytesMatch(DataBufferSP &data_sp,
                                      lldb::addr_t data_offset,
                                      lldb::addr_t data_length) {
  lldb_private::DataExtractor data;
  data.SetData(data_sp, data_offset, data_length);
  data.SetByteOrder(eByteOrderBig);
  lldb::offset_t offset = 0;
  uint16_t magic = data.GetU16(&offset);
  return XCOFFHeaderSizeFromMagic(magic) != 0;
}

bool ObjectFileXCOFF::ParseHeader() { return false; }

ByteOrder ObjectFileXCOFF::GetByteOrder() const { return eByteOrderBig; }

bool ObjectFileXCOFF::IsExecutable() const { return true; }

uint32_t ObjectFileXCOFF::GetAddressByteSize() const { return 8; }

void ObjectFileXCOFF::ParseSymtab(Symtab &lldb_symtab) {}

bool ObjectFileXCOFF::IsStripped() { return false; }

void ObjectFileXCOFF::CreateSections(SectionList &unified_section_list) {}

void ObjectFileXCOFF::Dump(Stream *s) {}

ArchSpec ObjectFileXCOFF::GetArchitecture() {
  ArchSpec arch_spec =
      ArchSpec(eArchTypeXCOFF, XCOFF::TCPU_PPC64, LLDB_INVALID_CPUTYPE);
  return arch_spec;
}

UUID ObjectFileXCOFF::GetUUID() { return UUID(); }

uint32_t ObjectFileXCOFF::GetDependentModules(FileSpecList &files) { return 0; }

ObjectFile::Type ObjectFileXCOFF::CalculateType() { return eTypeExecutable; }

ObjectFile::Strata ObjectFileXCOFF::CalculateStrata() { return eStrataUnknown; }

lldb::WritableDataBufferSP
ObjectFileXCOFF::MapFileDataWritable(const FileSpec &file, uint64_t Size,
                                     uint64_t Offset) {
  return FileSystem::Instance().CreateWritableDataBuffer(file.GetPath(), Size,
                                                         Offset);
}

ObjectFileXCOFF::ObjectFileXCOFF(const lldb::ModuleSP &module_sp,
                                 DataBufferSP data_sp,
                                 lldb::offset_t data_offset,
                                 const FileSpec *file,
                                 lldb::offset_t file_offset,
                                 lldb::offset_t length)
    : ObjectFile(module_sp, file, file_offset, length, data_sp, data_offset) {
  if (file)
    m_file = *file;
}

ObjectFileXCOFF::ObjectFileXCOFF(const lldb::ModuleSP &module_sp,
                                 DataBufferSP header_data_sp,
                                 const lldb::ProcessSP &process_sp,
                                 addr_t header_addr)
    : ObjectFile(module_sp, process_sp, header_addr, header_data_sp) {}
