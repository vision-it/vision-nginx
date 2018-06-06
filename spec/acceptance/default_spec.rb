require 'spec_helper_acceptance'

describe 'vision_nginx::ssl' do
  context 'with defaults' do
    it 'idempotentlies run' do
            pp = <<-FILE

        class { 'vision_nginx':        }

      FILE

            apply_manifest(pp, catch_failures: true)
            apply_manifest(pp, catch_changes: true)
    end
  end

  context 'SSL enabled' do
    describe file('/etc/apache2/ssl/current.key') do
      it { is_expected.to exist }
      it { is_expected.to be_mode 400 }
      it { is_expected.to contain 'foobar' }
    end
  end
end
