# encoding: utf-8
# 上街吧app服务器 8001 端口监控

k = '/data/www/apps/shangjieba_app/shared'
p = '8001'
passenger = '/usr/bin/passenger'

God.watch do |w|
  w.name = "sjb_#{p}"
  w.start = "#{passenger} start -a 0.0.0.0 -p #{p} -d -e production --pid-file #{k}/passenger.#{p}.pid"
  w.stop = "#{passenger} stop -p #{p} --pid-file #{k}/passenger.#{p}.pid"
  w.pid_file = "#{k}/passenger.#{p}.pid"
  w.behavior(:clean_pid_file)
  #
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 20.seconds
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 400.megabytes
      c.interval = 20.seconds
      c.times = [3, 5] # 3 out of 5 intevals
    end

    restart.condition(:cpu_usage) do |c|
      c.above = 70.percent
      c.interval = 20.seconds
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