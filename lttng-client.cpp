// Copyright FSL Lab Stony Brook University

#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>
#include <iostream>
#include <string>

int main(int argc, char *argv[]) {
  int process_id, process_group_id;

  process_id = getpid();
  process_group_id = getpgid(process_id);

  std::cout << "parent pid " << process_id << " process group id "
            << process_group_id << "\n";

  int child_pid = fork();

  if (child_pid == 0) {
    process_id = getpid();
    process_group_id = getpgid(process_id);
    if (setpgid(process_id, process_id) != 0) {
      std::cout << "problem while setting process group id\n";
    } else {
      process_group_id = getpgid(process_id);
    }

    std::cout << "child pid " << process_id << " child process group id "
              << process_group_id << "\n";


    /* TODO(Umit): output file make it parameterize */
    system("sudo lttng create nsession --output=/files/nsession");
    std::string tracking_str =
        "sudo lttng track -k --pid=" + std::to_string(process_group_id);
    system(tracking_str.c_str());
    system("sudo lttng enable-channel channel0 -k --discard --num-subbuf 32");
    system(
        "sudo lttng enable-event -s nsession -c channel0 --kernel --all "
        "--syscall");
    system("sudo lttng add-context -k --session=nsession --type=tid");

    // TODO(Umit): executable and parameters have to be paramerized */
    char *const exec_file = "readtest";
    char *const argv[] = {exec_file, nullptr};
    char *const env[] = {nullptr};
    system("sudo lttng start nsession");

    execve(exec_file, argv, env);
  }
  waitpid(child_pid, nullptr, 0);
  system("sudo lttng stop nsession");
  system("babeltrace /files/nsession/kernel > babeltrace.out");
  system("sudo lttng destroy nsession");
  return 0;
}
