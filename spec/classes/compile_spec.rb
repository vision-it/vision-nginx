require 'spec_helper'
require 'hiera'

describe 'vision_nginx' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do

      context 'compile' do
        it { is_expected.to compile.with_all_deps }
      end

    end
  end
end
