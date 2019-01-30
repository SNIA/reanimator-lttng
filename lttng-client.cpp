// Copyright FSL Lab Stony Brook University

#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>
#include <boost/program_options.hpp>
#include <iostream>
#include <string>

boost::program_options::variables_map get_options(int argc, char *argv[]) {
  namespace po = boost::program_options;
  po::options_description generic("Generic options");

  generic.add_options()("help,h", "lttng-client [-s, -d] -e [COMMAND]");

  po::options_description config("Configuration");
  config.add_options()("verbose,v", "prints execution logs")(
      "session-directory,s", po::value<std::string>(),
      "lttng session directory path")(
      "exec,e", po::value<std::string>(),
      "executable string which is going to be run through lttng")(
      "ds-output,d", po::value<std::string>(), "ds output file path");

  po::options_description test_program_parameters("test program parameters");
  test_program_parameters.add_options()("test program parameters,p",
                                        po::value<std::vector<std::string>>(),
                                        "test program parameters");

  po::options_description cmdline_options;
  cmdline_options.add(generic).add(config).add(test_program_parameters);

  po::options_description visible("Allowed options");
  visible.add(generic).add(config);

  po::variables_map vm;
  po::store(po::command_line_parser(argc, argv).options(cmdline_options).run(),
            vm);
  po::notify(vm);

  if (vm.count("help") != 0u) {
    std::cerr << visible << std::endl;
    exit(EXIT_SUCCESS);
  }

  return vm;
}

void process_options(int argc, char *argv[], bool *verbose,
                     std::string *session_directory) {
  boost::program_options::variables_map options_vm = get_options(argc, argv);

  if (options_vm.count("verbose") != 0u) {
    *verbose = true;
    std::cout << "verbose mode on"
              << "\n";
  }

  if (options_vm.count("session-directory") != 0u) {
    *session_directory = options_vm["session-directory"].as<std::string>();
  } else {
    *session_directory = "/tmp/session-capture";
  }
}

void lttng_config(void) {
  system(
      "sudo lttng enable-channel channel0 -k --discard --num-subbuf 32 >> "
      "lttng-client.log");
  system(
      "sudo lttng enable-event -s strace2ds-session -c channel0 --kernel "
      "--all "
      "--syscall >> lttng-client.log");
  system(
      "sudo lttng add-context -k --session=strace2ds-session --type=tid >> "
      "lttng-client.log");
  system(
      "sudo lttng add-context -k --session=strace2ds-session --type=pid >> "
      "lttng-client.log");
}

int main(int argc, char *argv[]) {
  int process_id, process_group_id;
  bool verbose = false;
  std::string executable_name = "readtest";
  std::string ds_output_name = executable_name + ".ds";
  std::string session_directory;

  process_id = getpid();
  process_group_id = getpgid(process_id);

  process_options(argc, argv, &verbose, &session_directory);

  if (verbose) {
    std::cout << "parent pid " << process_id << " process group id "
              << process_group_id << "\n";
  }

  int child_pid = fork();

  if (child_pid == 0) {
    process_id = getpid();
    process_group_id = getpgid(process_id);
    if (setpgid(process_id, process_id) != 0) {
      std::cerr << "problem while setting process group id\n";
    } else {
      process_group_id = getpgid(process_id);
    }
    if (verbose) {
      std::cout << "child pid " << process_id << " child process group id "
                << process_group_id << "\n";
    }

    std::string session_folder_create = "mkdir -p " + session_directory;
    system(session_folder_create.c_str());
    /* TODO(Umit): output file make it parameterize */
    std::string create_session_cmd =
        "sudo lttng create strace2ds-session --output=";
    create_session_cmd += session_directory + " >> lttng-client.log";
    system(create_session_cmd.c_str());

    std::string tracking_str =
        "sudo lttng track -k --pid=" + std::to_string(process_group_id) +
        " >> lttng-client.log";
    system(tracking_str.c_str());

    lttng_config();

    // TODO(Umit): executable and parameters have to be paramerized */
    char *const exec_file = strdup(executable_name.c_str());
    char *const argv[] = {exec_file, nullptr};
    char *const env[] = {nullptr};
    system("sudo lttng start strace2ds-session >> lttng-client.log");

    execve(exec_file, argv, env);
  }
  waitpid(child_pid, nullptr, 0);
  system("sudo lttng stop strace2ds-session >> lttng-client.log");

  std::string permission_update = "sudo chmod -R 755 " + session_directory;
  system(permission_update.c_str());

  // TODO(Umit): dataseries output file parameterized
  std::string babeltrace_cmd = "babeltrace " + session_directory +
                               "/kernel -w " + ds_output_name +
                               " -x /tmp/buffer-capture.dat";
  system(babeltrace_cmd.c_str());
  system("sudo lttng destroy strace2ds-session >> lttng-client.log");
  system("sudo rm -rf /tmp/buffer-capture.dat");
  return 0;
}
