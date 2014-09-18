# encoding: utf-8
# 上街吧后端处理服务器 sidekiq 端口 redis 监控


# passenger = '/usr/bin/passenger'
k = '/data/www/apps/shangjieba_job'
p = '3001'
God.watch do |w|
  w.name = "job_#{p}"
  w.start = "cd #{k}/current && bundle exec sidekiq -C config/sidekiq.yml -d -e production"
  w.stop = "cd #{k}/current && bundle exec sidekiqctl quiet log/pids/sidekiq.pid && bundle exec sidekiqctl stop log/pids/sidekiq.pid"
  # w.start = "#{passenger} start -a 0.0.0.0 -p #{p} -d -e production --pid-file #{k}/passenger.#{p}.pid"
  # w.stop = "#{passenger} stop -p #{p} --pid-file #{k}/passenger.#{p}.pid"
  # w.pid_file = "#{k}/passenger.#{p}.pid"
  w.behavior(:clean_pid_file)
  # w.log = "#{k}/log/god_#{p}.log"
  #
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 20.seconds
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 300.megabytes
      c.interval = 60.seconds
      c.times = [3, 5] # 3 out of 5 intevals
    end

    restart.condition(:cpu_usage) do |c|
      c.above = 70.percent
      c.interval = 60.seconds
      c.times = 5
    end
  end

  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end

end
