
[1mFrom:[0m /home/bensouc/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/railties-7.0.5/lib/rails/command.rb:54 Rails::Command.invoke:

    [1;34m30[0m: [32mdef[0m [1;34minvoke[0m(full_namespace, args = [], **config)
    [1;34m31[0m:   namespace = full_namespace = full_namespace.to_s
    [1;34m32[0m: 
    [1;34m33[0m:   [32mif[0m char = namespace =~ [35m[1;35m/[0m[35m:([1;35m\w[0m[35m+)$[1;35m/[0m[35m[0m
    [1;34m34[0m:     command_name, namespace = [1;32m$1[0m, namespace.slice([1;34m0[0m, char)
    [1;34m35[0m:   [32melse[0m
    [1;34m36[0m:     command_name = namespace
    [1;34m37[0m:   [32mend[0m
    [1;34m38[0m: 
    [1;34m39[0m:   command_name, namespace = [31m[1;31m"[0m[31mhelp[1;31m"[0m[31m[0m, [31m[1;31m"[0m[31mhelp[1;31m"[0m[31m[0m [32mif[0m command_name.blank? || [1;34;4mHELP_MAPPINGS[0m.include?(command_name)
    [1;34m40[0m:   command_name, namespace, args = [31m[1;31m"[0m[31mapplication[1;31m"[0m[31m[0m, [31m[1;31m"[0m[31mapplication[1;31m"[0m[31m[0m, [[31m[1;31m"[0m[31m--help[1;31m"[0m[31m[0m] [32mif[0m rails_new_with_no_path?(args)
    [1;34m41[0m:   command_name, namespace = [31m[1;31m"[0m[31mversion[1;31m"[0m[31m[0m, [31m[1;31m"[0m[31mversion[1;31m"[0m[31m[0m [32mif[0m [31m[1;31m%w([0m[31m -v --version [1;31m)[0m[31m[0m.include?(command_name)
    [1;34m42[0m: 
    [1;34m43[0m:   original_argv = [1;36mARGV[0m.dup
    [1;34m44[0m:   [1;36mARGV[0m.replace(args)
    [1;34m45[0m: 
    [1;34m46[0m:   command = find_by_namespace(namespace, command_name)
    [1;34m47[0m:   [32mif[0m command && command.all_commands[command_name]
    [1;34m48[0m:     command.perform(command_name, args, config)
    [1;34m49[0m:   [32melse[0m
    [1;34m50[0m:     args = [[31m[1;31m"[0m[31m--describe[1;31m"[0m[31m[0m, full_namespace] [32mif[0m [1;34;4mHELP_MAPPINGS[0m.include?(args[[1;34m0[0m])
    [1;34m51[0m:     find_by_namespace([31m[1;31m"[0m[31mrake[1;31m"[0m[31m[0m).perform(full_namespace, args, config)
    [1;34m52[0m:   [32mend[0m
    [1;34m53[0m: [32mensure[0m
 => [1;34m54[0m:   [1;36mARGV[0m.replace(original_argv)
    [1;34m55[0m: [32mend[0m

