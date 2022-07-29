git_plugin = self


namespace :deploy do
  namespace :blue_green do
    desc "Restart webserver"
    task :restart do
      on roles(:app) do
        invoke "unicorn:restart"
      end
    end

    desc "Make the current app live"
    task :live do
      on roles(:app) do   
        git_plugin.health_check do
          unicorn_pid = "#{fetch(:bg_live_dir)}/tmp/pids/unicorn.pid"

          if test("[ -e #{unicorn_pid} ]")
            if test("kill -0 #{git_plugin.live_pid(unicorn_pid)}")
              info "stopping unicorn..."
              execute :kill, "-s QUIT", git_plugin.live_pid(unicorn_pid)
            else
              info "cleaning up dead unicorn pid..."
              execute :rm, unicorn_pid
            end
          else
            info "unicorn live not running..."
          end

          git_plugin.live_task_run
        end
      end
    end

    desc "Deploy your project to pre environment"
    task :pre do
      on roles(:app) do
        # Do nothing
      end
    end

    desc "Health check blue/screen"
    task :health_check do
      on roles(:app) do
        git_plugin.health_check do
          info "Successful"
        end
      end
    end

    desc "Rollback to the previous live release"
    task :rollback do
      on roles(:app) do
        git_plugin.health_check do
          unicorn_pid = "#{fetch(:bg_live_dir)}/tmp/pids/unicorn.pid"

          if test("[ -e #{unicorn_pid} ]")
            if test("kill -0 #{git_plugin.live_pid(unicorn_pid)}")
              info "stopping unicorn..."
              execute :kill, "-s QUIT", git_plugin.live_pid(unicorn_pid)
            else
              info "cleaning up dead unicorn pid..."
              execute :rm, unicorn_pid
            end
          else
            info "unicorn live not running..."
          end

          git_plugin.rollback_task_run
        end
      end
    end

    after "deploy:blue_green:pre", "deploy"
  end
end
