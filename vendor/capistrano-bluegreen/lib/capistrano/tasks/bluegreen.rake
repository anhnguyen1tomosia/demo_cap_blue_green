git_plugin = self

namespace :deploy do
  namespace :blue_green do
    desc "Make the current app live"
    task :live do
      on roles(:app) do
        git_plugin.live_task_run
      end
    end

    desc "Deploy your project to pre environment"
    task :pre do
      on roles(:app) do
        # Do nothing
      end
    end

    after "deploy:blue_green:pre", "deploy"
  end
end
