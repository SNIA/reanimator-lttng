// Copyright FSL Lab Stony Brook University

#include <fstream>
#include <iostream>

int main() {
  std::ifstream file("/tmp/buffer-capture.dat",
                     std::ios::in | std::ios::binary);

  int record_id;
  uint64_t sizeOfBuffer;
  if (file.is_open()) {
    while (!file.eof()) {
      file.read((char*)&record_id, sizeof(record_id));
      file.read((char*)&sizeOfBuffer, sizeof(sizeOfBuffer));
      auto buffer = new char[sizeOfBuffer];
      file.read(buffer, sizeof(buffer));
      delete[] buffer;
      std::cout << record_id << " " << sizeOfBuffer << "\n";
      return 0;
    }
    file.close();
  } else {
    std::cout << "Unable to open file\n";
  }
  return 0;
}
