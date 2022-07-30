require 'capistrano/bundler'
require 'capistrano/plugin'
require "capistrano3/unicorn"
require 'uri'
require 'net/http'

module Capistrano
  class Bluegreen < Capistrano::Plugin

    def define_tasks
      eval_rakefile File.expand_path('tasks/bluegreen.rake', __dir__)
    end

    def set_defaults
      set_if_empty :bg_live_dir, -> { File.join(deploy_to, 'current_live') }
      set_if_empty :bg_previous_dir, -> { File.join(deploy_to, 'previous_live') }
      set_if_empty :bg_health_check_path, -> { 'http://localhost:55001/' }
      set_if_empty :bg_health_check_count, -> { 5 }
      set_if_empty :bg_live_unicorn_pid, -> { File.join('current_live', "tmp", "pids", "unicorn.pid") }
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
      previous_live = fullpath_by_symlink fetch(:bg_live_dir)

      do_symlink previous_live, fetch(:bg_previous_dir) unless current_live.empty?
      do_symlink current_live, fetch(:bg_live_dir)
    end

    def health_check(&block)
      health_check_path  = fetch(:bg_health_check_path)
      health_check_count = fetch(:bg_health_check_count)

      uri = URI(health_check_path)
      res = Net::HTTP.get_response(uri)

      loop do
        sleep 1
        health_check_count += 1
        backend.info "Health checking ... #{health_check_path}"
        
        if res.is_a?(Net::HTTPSuccess)
          backend.info "Response status 200 #{health_check_path}"
          yield block
          break
        else
          if health_check_count >= 5
            backend.info "Run health check #{health_check_count} time, but not response status 200"
            break
          end
        end
      end
    end

    def rollback_task_run
      previous_live = fullpath_by_symlink fetch(:bg_previous_dir)

      unless previous_live.empty?
        backend.info previous_live
        current_path = previous_live
        
        set :unicorn_config_path, -> { File.join(previous_live, "config", "unicorn.rb") }
        set :unicorn_pid, -> { File.join(previous_live, "tmp", "pids", "unicorn.pid") }

        Rake::Task["unicorn:restart"].execute

        do_symlink previous_live, fetch(:bg_live_dir)
      else
        backend.info "no old release to rollback"
      end
    end

    def live_pid(path)
      "`cat #{path}`"
    end
  end
end
