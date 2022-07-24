require 'capistrano/bundler'
require 'capistrano/plugin'

module Capistrano
  class Bluegreen < Capistrano::Plugin

    def define_tasks
      eval_rakefile File.expand_path('tasks/bluegreen.rake', __dir__)
    end

    def set_defaults
      set_if_empty :blue_green_live_dir, -> { File.join(deploy_to, 'current_live') }
      set_if_empty :blue_green_previous_dir, -> { File.join(deploy_to, 'previous_live') }
      set_if_empty :blue_green_health_check, -> { 'http://localhost:55001/' }
    end

    def fullpath_by_symlink sym
      backend.capture("if [ -L #{sym} ]; then readlink #{sym}; fi ").strip
    end
    
    def dirs_inside path
      backend.capture("ls -xt #{path}").split.reverse
    end
    
    def do_symlink from, to
      backend.execute("rm -rf #{to} && ln -s #{from} #{to}")
    end
    
    def remove_dirs dirs
      try_sudo "rm -rf #{dirs}"
    end

    def live_task_run
      current_live = fullpath_by_symlink current_path
      previous_live = fullpath_by_symlink fetch(:blue_green_live_dir)

      do_symlink previous_live, fetch(:blue_green_previous_dir) unless current_live.empty?
      do_symlink current_live, fetch(:blue_green_live_dir)
    end

    def live_pid(path)
      "`cat #{path}`"
    end
  end
end
