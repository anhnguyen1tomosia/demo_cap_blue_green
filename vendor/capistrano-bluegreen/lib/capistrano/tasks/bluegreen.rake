git_plugin = self


namespace :deploy do
  namespace :blue_green do
    desc "Make the current app live"
    task :live do
      on roles(:app) do   
        uri = URI(fetch(:blue_green_health_check))
        res = Net::HTTP.get_response(uri)
        health_check_count = 1

        loop do
          sleep 1
          health_check_count += 1
          info "Health checking ... #{fetch(:blue_green_health_check)}"
          
          if res.is_a?(Net::HTTPSuccess)
            info "#{fetch(:blue_green_health_check)} response status 200"
            unicorn_pid = "#{fetch(:blue_green_live_dir)}/tmp/pids/unicorn.pid"

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
            break
          else
            break if health_check_count >= 5
          end
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

    after "deploy:blue_green:pre", "deploy"
  end
end
