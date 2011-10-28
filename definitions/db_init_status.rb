# Cookbook Name:: db
#
# Copyright (c) 2011 RightScale, Inc.
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# == Used to set and check node[:db][:init_status].
# When our database is at a point where it can be used, this is used to set the database
# as 'initialized'.  Other recipes that require the database to be 'initialized' use this
# to confirm.  If a check is done and a state is not what is expected, this receipe will
# error out with raise.
# == Params
# name(String):: set to :set, :reset, or :check.  :set will set node[:db][:init_status] (state)
#   to :initialized.  :reset will set state to :uninitialized, :check will check requiring
#   expected_state param.
# expected_state(String):: when name set to :check, this is what the state should be.  If it
#   is not this state, will raise an error with the message of error_message param.
# error_message(String):: the error message that is used if :check results in an error.
# == Exceptions
# :name param must be either :set, :reset, :check or will raise an error.


define :db_init_status, :expected_state => :initialized, :error_message => "ERROR: your database is not in expected state" do

  new_action     = params[:name]
  expected_state = params[:expected_state]

  # Current valid status: initialized, uninitialized
  ruby_block "Setting initialization status #{new_action}" do
    block do
      current_state = node[:db][:init_status]

      case new_action
      when :set
        Chef::Log.info "changing status from #{current_state} to initialized"
        node[:db][:init_status] = :initialized
      when :reset
        Chef::Log.info "changing status from #{current_state} to uninitialized"
        node[:db][:init_status] = :uninitialized
      when :check
        Chef::Log.info "checking if database is #{expected_state} (#{current_state})"
        raise params[:error_message] unless current_state.to_s == expected_state.to_s
        Chef::Log.info "expected state found"
      else
        raise "ERROR: Must specify :set,:reset, or :check"
      end
    end
  end

end 
