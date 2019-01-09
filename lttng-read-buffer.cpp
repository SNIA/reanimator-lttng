// Copyright FSL Lab Stony Brook University

#include <fstream>
#include <iostream>

int main() {
  std::ifstream file("/tmp/buffer-capture.dat",
                     std::ios::in | std::ios::binary);
  uint64_t offset = 0, record_id = 0, sizeOfBuffer = 0, numberOfRecords = 0;
  if (file.is_open()) {
    auto begin_pos = file.tellg();
    file.seekg(0, std::ios::end);
    auto end_pos = file.tellg();
    file.seekg(0, std::ios::beg);
    while (offset < (end_pos - begin_pos)) {
      file.read((char*)&record_id, sizeof(record_id));
      file.read((char*)&sizeOfBuffer, sizeof(sizeOfBuffer));
      std::cout << std::hex << record_id << " " << sizeOfBuffer << " " << offset
                << "\n";
      auto buffer = new char[sizeOfBuffer];
      file.read(buffer, sizeof(buffer));
      delete[] buffer;
      offset += (sizeof(record_id) + sizeof(offset) + sizeOfBuffer);
      file.seekg(offset, std::ios::beg);
      numberOfRecords++;
    }
    file.close();
  } else {
    std::cout << "Unable to open file\n";
  }
  std::cout << std::dec << "Number of records: " << numberOfRecords << "\n";
  return 0;
}
