OUTPUT_EXECUTABLE_NAME :: "voronoi";

#run {
    set_build_options_dc(.{do_output = false});

    build_output_directory := "run_tree";

    make_directory_if_it_does_not_exist(build_output_directory, recursive = true);

    w := compiler_create_workspace("voronoi");

    options := get_build_options(w);

    copy_commonly_propagated_fields(get_build_options(), *options);

    options.output_executable_name = OUTPUT_EXECUTABLE_NAME; 
    options.output_path = build_output_directory;

    set_build_options(options, w);

    compiler_begin_intercept(w);

    add_build_file("source/voronoi.jai", w);

    while true {
        message := compiler_wait_for_message();

        if message.kind == {
            case .ERROR;
                exit(1);
            case .COMPLETE;
                break;
        }
    }

    compiler_end_intercept(w);
}

#import "Basic";
#import "Compiler";
#import "File";
