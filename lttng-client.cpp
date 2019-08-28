// Copyright FSL Lab Stony Brook University

#include <stdlib.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <unistd.h>
#include <boost/program_options.hpp>
#include <chrono>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>

#define PRE_LOG_MESSAGE std::left << std::setw(15) << ">>>>>>>>>>>"
#define POST_LOG_MESSAGE ""
#define PRINT_STATISTICS

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
  test_program_parameters.add_options()("test-program-parameters,p",
                                        po::value<std::vector<std::string>>(),
                                        "test program parameters");

  po::options_description cmdline_options;
  cmdline_options.add(generic).add(config).add(test_program_parameters);

  po::options_description visible("Allowed options");
  visible.add(generic).add(config);

  po::variables_map vm;
  po::store(po::command_line_parser(argc, argv)
                .options(cmdline_options)
                .allow_unregistered()
                .run(),
            vm);
  po::notify(vm);

  if (vm.count("help") != 0u) {
    std::cerr << visible << std::endl;
    exit(EXIT_SUCCESS);
  }

  return vm;
}

void process_options(int argc, char *argv[], bool *verbose,
                     std::string *session_directory, std::string *exec_name,
                     std::string *ds_output_name, int *executable_idx) {
  boost::program_options::variables_map options_vm = get_options(argc, argv);

  if (options_vm.count("verbose") != 0u) {
    *verbose = true;
  }

  if (options_vm.count("exec") != 0u) {
    *exec_name = options_vm["exec"].as<std::string>();
  } else {
    assert(0);
  }

  if (options_vm.count("session-directory") != 0u) {
    *session_directory = options_vm["session-directory"].as<std::string>();
  } else {
    *session_directory = "/tmp/session-capture";
  }

  if (options_vm.count("ds-output") != 0u) {
    *ds_output_name = options_vm["ds-output"].as<std::string>();
  } else {
    *ds_output_name = (*exec_name) + ".ds";
  }

  for (int i = 0; i < argc; i++) {
    auto parameter = argv[i];
    std::string var(parameter);
    if (var == "-e") {
      *executable_idx = i;
    }
  }
}

void lttng_config(void) {
  system(
      "sudo lttng enable-channel channel0 -k --discard --num-subbuf 64 >> "
      "lttng-client.log");
  system(
      "sudo lttng enable-event -s strace2ds-session -c channel0 --kernel "
      "--all "
      "--syscall >> lttng-client.log");
  system(
      "sudo lttng enable-event -s strace2ds-session -c channel0 --kernel "
      "mm_filemap_add_to_page_cache >> lttng-client.log");
  system(
      "sudo lttng enable-event -s strace2ds-session -c channel0 --kernel "
      "mm_filemap_fsl_read >> lttng-client.log");
  system(
      "sudo lttng enable-event -s strace2ds-session -c channel0 --kernel "
      "fsl_writeback_dirty_page >> lttng-client.log");
  system(
      "sudo lttng enable-event -s strace2ds-session -c channel0 --kernel "
      "writeback_dirty_page >> lttng-client.log");
  // system(
  //     "sudo lttng enable-event -s strace2ds-session -c channel0 --kernel "
  //     "x86_exceptions_page_fault_user >> lttng-client.log");
  system(
      "sudo lttng add-context -k --session=strace2ds-session --type=tid >> "
      "lttng-client.log");
  system(
      "sudo lttng add-context -k --session=strace2ds-session --type=pid >> "
      "lttng-client.log");
}

int main(int argc, char *argv[]) {
  int process_id, process_group_id;
  int child_process_parameter_idx = 0;
  bool verbose = false;
  std::string executable_name, ds_output_name, session_directory;
  std::ofstream report;

  process_id = getpid();
  process_group_id = getpgid(process_id);
  std::chrono::high_resolution_clock::time_point *timers =
      (std::chrono::high_resolution_clock::time_point *)mmap(
          nullptr, sizeof(std::chrono::high_resolution_clock::time_point) * 2,
          PROT_READ | PROT_WRITE, MAP_ANONYMOUS | MAP_SHARED, 0, 0);
  std::chrono::high_resolution_clock::time_point whole_trace_start =
      std::chrono::high_resolution_clock::now();

  process_options(argc, argv, &verbose, &session_directory, &executable_name,
                  &ds_output_name, &child_process_parameter_idx);

  std::ios_base::fmtflags flags = std::cout.flags();
  if (verbose) {
    std::cout << PRE_LOG_MESSAGE << "parent pid " << process_id
              << " process group id " << process_group_id << POST_LOG_MESSAGE
              << std::endl;
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
      std::cout << PRE_LOG_MESSAGE << "child pid " << process_id
                << " child process group id " << process_group_id
                << POST_LOG_MESSAGE << std::endl;
    }

    std::string session_folder_create = "mkdir -p " + session_directory;
    system(session_folder_create.c_str());
    std::string create_session_cmd =
        "sudo lttng create strace2ds-session --output=";
    create_session_cmd += session_directory + " >> lttng-client.log";
    system(create_session_cmd.c_str());

    std::string tracking_str =
        "sudo lttng track -k --pid=" + std::to_string(process_group_id) +
        " >> lttng-client.log";
    system(tracking_str.c_str());

    lttng_config();

    char *const exec_file = strdup(executable_name.c_str());
    char *const env[] = {nullptr};
    if (verbose) {
      std::cout << PRE_LOG_MESSAGE << "lttng start capturing"
                << POST_LOG_MESSAGE << std::endl;
    }
    system("sudo lttng start strace2ds-session >> lttng-client.log");

    timers[0] = std::chrono::high_resolution_clock::now();

    execve(exec_file, (char *const *)&argv[child_process_parameter_idx + 1],
           env);
  }
  waitpid(child_pid, nullptr, 0);

  timers[1] = std::chrono::high_resolution_clock::now();

  system("sudo lttng untrack -k --pid --all >> lttng-client.log");

  if (verbose) {
    std::cout << PRE_LOG_MESSAGE << "execution finished" << std::endl;
    std::cout << PRE_LOG_MESSAGE << "lttng stop capturing" << POST_LOG_MESSAGE
              << std::endl;
  }
  system("sudo lttng stop strace2ds-session >> lttng-client.log");

  std::chrono::high_resolution_clock::time_point whole_trace_end =
      std::chrono::high_resolution_clock::now();

  std::string permission_update = "sudo chmod -R 755 " + session_directory;
  system(permission_update.c_str());

  // std::string babeltrace_cmd =
  //     "babeltrace " + session_directory + "/kernel -w " + ds_output_name +
  //     " -x /tmp/buffer-capture.dat" + " >> babeltrace.bt";
  std::string babeltrace_cmd =
      "babeltrace " + session_directory + "/kernel " + " >> babeltrace.bt";

  if (verbose) {
    std::cout << PRE_LOG_MESSAGE << "babeltrace started" << std::endl;
  }

  std::chrono::high_resolution_clock::time_point babeltrace_start =
      std::chrono::high_resolution_clock::now();

  system(babeltrace_cmd.c_str());

  std::chrono::high_resolution_clock::time_point babeltrace_stop =
      std::chrono::high_resolution_clock::now();

  if (verbose) {
    std::cout << PRE_LOG_MESSAGE << "babeltrace ended" << std::endl;
  }

  auto babeltrace_timing =
      std::chrono::duration_cast<std::chrono::milliseconds>(babeltrace_stop -
                                                            babeltrace_start)
          .count();
  auto total_tracing_timing =
      std::chrono::duration_cast<std::chrono::milliseconds>(whole_trace_end -
                                                            whole_trace_start)
          .count();
  auto just_tracing_timing =
      std::chrono::duration_cast<std::chrono::milliseconds>(timers[1] -
                                                            timers[0])
          .count();
#ifdef PRINT_STATISTICS
  std::cout << PRE_LOG_MESSAGE << std::left << std::setw(40)
            << "babeltrace timing" << std::left << std::setw(5) << ":"
            << std::left << std::setw(5) << babeltrace_timing << "\n";

  std::cout << PRE_LOG_MESSAGE << std::left << std::setw(40)
            << "tracing total timing" << std::left << std::setw(5) << ":"
            << std::left << std::setw(5) << total_tracing_timing << "\n";

  std::cout << PRE_LOG_MESSAGE << std::left << std::setw(40)
            << "tracing just for execution period timing" << std::left
            << std::setw(5) << ":" << std::left << std::setw(5)
            << just_tracing_timing << "\n";
#endif

  report.open("report.txt", std::ios::app);
  report << just_tracing_timing << "\t" << total_tracing_timing << "\t"
         << babeltrace_timing << "\n";
  report.close();

  system("sudo lttng destroy strace2ds-session >> lttng-client.log");
  system("sudo rm -rf /tmp/buffer-capture.dat");

  std::cout.flags(flags);
  return 0;
}
