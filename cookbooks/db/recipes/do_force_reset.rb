# Cookbook Name:: db
#
# Copyright (c) 2011 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

rs_utils_marker :begin

log "  Brute force tear down of the setup....."
DATA_DIR = node[:db][:data_dir]

log "  Stopping database..."
db DATA_DIR do
  action :stop 
end

log "  Make sure the DB is really stopped (hack around occasional stop failure)..."
bash "Kill the DB" do
  code <<-EOH
  killall -s 9 -q -r 'mysql.*' || true
  EOH
end

log "  Resetting block device..."
block_device DATA_DIR do
  lineage node[:db][:backup][:lineage]
  action :reset
end

log "  Cleaning stuff..."
bash "cleaning stuff" do
  code <<-EOH
  rm -f #{node[:rs_utils][:db_backup_file]} #{::File.join('/var/lock', DATA_DIR.gsub('/', '_') + '.lock')} /var/run/rightscale_tools_database_lock.pid
  rmdir #{DATA_DIR}
  rs_tag -r 'rs_dbrepl:*'
  EOH
end

sys_dns "cleaning dns" do
  provider "sys_dns_#{node[:sys_dns][:choice]}"

  id node[:sys_dns][:id]
  user node[:sys_dns][:user]
  password node[:sys_dns][:password]
  address '1.1.1.1'

  action :set_private
end

ruby_block "Setting db_restored state to false" do
  block do
    node[:db][:db_restored] = false
  end
end

log "  Resetting database, then starting database..."
db DATA_DIR do
  action [ :reset, :start ]
end

rs_utils_marker :end