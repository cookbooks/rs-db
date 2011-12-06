#
# Cookbook Name:: db
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.

# NOTE - any changes here should also be considered for 'do_restore'

rs_utils_marker :begin

DATA_DIR = node[:db][:data_dir]

db_init_status :check do
  expected_state :uninitialized
  error_message "Database already restored.  To over write existing database run do_force_reset before this recipe"
end

log "  Running pre-restore checks..."
db DATA_DIR do
  action :pre_restore_check
end

log "======== LINEAGE ========="
log node[:db][:backup][:lineage]
log "======== LINEAGE ========="

# ROS restore requires a setup, but VOLUME restore does not.
# Since secondary is only ROS we need the folowing create action
log "  Creating block device..."
block_device DATA_DIR do
  lineage node[:db][:backup][:lineage]
  action :create
end

log "  Stopping database..."
db DATA_DIR do
  action :stop
end

log "  Performing Secondary Restore from #{node[:db][:backup][:secondary_location]}..."
# Requires block_device DATA_DIR to be instantiated
# previously. Make sure block_device::default recipe has been run.
block_device DATA_DIR do
  provider "block_device_ros"
  cloud node[:cloud][:provider]
  storage_cloud node[:db][:backup][:secondary_location].downcase
  rackspace_snet node[:block_device][:rackspace_snet]
  lineage node[:db][:backup][:lineage]
  timestamp_override node[:db][:backup][:timestamp_override]
  storage_container node[:db][:backup][:secondary_container]
  persist false
  action :restore
end

log "  Setting state of database to be 'initialized'..."
db_init_status :set

log "  Running post-restore cleanup..."
db DATA_DIR do
  action :post_restore_cleanup
end

log "  Starting database..."
db DATA_DIR do
  action [ :start, :status ]
end

rs_utils_marker :end
