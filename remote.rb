require 'json'
require 'net/http'
require 'uri'

# Commands for remote access
def remote(params)
  case (params[:command])
  when "status"
    return node_status(params)
  when "resource_status"
    return resource_status(params)
  when "create_cluster"
    return create_cluster(params)
  when "set_corosync_conf"
    puts "#{params['corosync_conf']}"
  when "cluster_start"
    return cluster_start()
  when "cluster_stop"
    return cluster_stop()
  end
end

def cluster_start()
    puts "Starting Daemons"
    puts `#{PCS} start`
end

def cluster_stop()
    puts "Starting Daemons"
    puts `#{PCS} stop`
end


def create_cluster(params)
  if params[:corosync_conf] != nil and params[:corosync_conf] != ""
    puts "#{params[:corosync_conf]}"
    cluster_stop()
    FileUtils.cp(COROSYNC_CONF,COROSYNC_CONF + "." + Time.now.to_i.to_s)
    File.open("/etc/corosync/corosync.conf",'w') {|f|
      f.write(params[:corosync_conf])
    }
    cluster_start()
  else
    puts "Invalid corosync.conf file"
  end
end

def node_status(params)
  if params[:node] != nil and params[:node] != "" and params[:node] != @@cur_node_name
    begin
      uri = URI.parse("http://#{params[:node]}:2222/remote/status?hello=1")
      output = Net::HTTP::get_response(uri)
      return output.body
    rescue
      return '{"noresponse":true}'
    end
  end
  uptime = `uptime`.chomp
  corosync_status = system("/etc/init.d/corosync", "status")
  pacemaker_status = system("/etc/init.d/pacemaker", "status")
  status = {"uptime" => uptime, "corosync" => corosync_status, "pacemaker" => pacemaker_status }
  ret = JSON.generate(status)
  return ret
end

def resource_status(params)
  resource_id = params[:resource]
  @resources = getResources
  location = ""
  res_status = ""
  @resources.each {|r|
    if r.id == resource_id
      if r.failed
	res_status =  "Failed"
      elsif !r.active
	res_status = "Inactive"
      else
	res_status = "Running"
      end
      if r.nodes.length != 0
	location = r.nodes[0].name
	break
      end
    end
  }
  status = {"location" => location, "status" => res_status}
  return JSON.generate(status)
end