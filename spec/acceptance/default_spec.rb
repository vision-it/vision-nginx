require 'spec_helper_acceptance'

describe 'vision_nginx' do
  context 'with defaults' do
    it 'idempotentlies run' do
      pp = <<-FILE
        class { 'vision_nginx': }
      FILE

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end
  end

  context 'package installed' do
    describe package('nginx-light') do
      it { is_expected.to be_installed }
    end
  end

  context 'files provisioned' do
    describe file('/tmp/nginx') do
      it { is_expected.to be_directory }
    end

    describe file('/etc/nginx') do
      it { is_expected.to be_symlink }
      it { is_expected.to be_linked_to('/tmp/nginx') }
    end

    describe file('/tmp/nginx/ssl') do
      it { is_expected.to be_directory }
      it { is_expected.to be_mode(500) }
      it { is_expected.to be_owned_by('root') }
    end

    describe file('/tmp/nginx/ssl/private-key.pem') do
      it { is_expected.to be_file }
      it { is_expected.to be_mode(600) }
      its(:content) { is_expected.to match('-----BEGIN PRIVATE KEY-----') }
      its(:content) { is_expected.to match('-----END PRIVATE KEY-----') }
    end

    describe file('/tmp/nginx/ssl/cert.pem') do
      it { is_expected.to be_file }
      it { is_expected.to be_mode(600) }
      its(:content) { is_expected.to match('-----BEGIN CERTIFICATE-----') }
      its(:content) { is_expected.to match('-----END CERTIFICATE-----') }
    end

    describe x509_certificate('/tmp/nginx/ssl/cert.pem') do
      it { should be_certificate }
    end

    describe file('/tmp/nginx/ssl/dhparams.pem') do
      it { is_expected.to be_file }
      it { is_expected.to be_mode(600) }
      its(:content) { is_expected.to match('-----BEGIN DH PARAMETERS-----') }
      its(:content) { is_expected.to match('-----END DH PARAMETERS-----') }
    end

    describe file('/tmp/nginx/nginx.conf') do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match('MANAGED BY PUPPET') }
      its(:content) { is_expected.to match('server_tokens off;') }
      its(:content) { is_expected.to match('worker_processes auto;') }
      its(:content) { is_expected.not_to match('worker_processes 1;') }
    end

    describe file('/tmp/nginx/sites-enabled/www.conf') do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match('MANAGED BY PUPPET') }
      its(:content) { is_expected.to match(/ssl_certificate (.*) \/tmp\/nginx\/ssl\/cert.pem;/) }
      its(:content) { is_expected.to match(/ssl_certificate_key (.*) \/tmp\/nginx\/ssl\/private-key.pem;/) }
      its(:content) { is_expected.to match(/ssl_dhparam (.*) \/tmp\/nginx\/ssl\/dhparams.pem;/) }
      its(:content) { is_expected.to match(/listen (.*) \*:443 ssl default_server;/) }
      its(:content) { is_expected.not_to match('http2') }
    end

    describe file('/tmp/nginx/sites-enabled/redirect.conf') do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match('MANAGED BY PUPPET') }
      its(:content) { is_expected.to match(/listen (.*) *:80 default_server;/) }
      its(:content) { is_expected.to match(/access_log (.*) off;/) }

      its(:content) { is_expected.not_to match('http2') }
      its(:content) { is_expected.not_to match('ssl_certificate') }
      its(:content) { is_expected.not_to match('ssl_certificate_key') }
      its(:content) { is_expected.not_to match('ssl_dhparam') }
    end
  end

  context 'config valid' do
    describe command('/usr/sbin/nginx -c /tmp/nginx/nginx.conf -t') do
      its(:stderr) { should contain(/syntax is ok/) }
      its(:stderr) { should contain(/test is successful/) }
      its(:exit_status) { should eq 0 }
    end
  end
end
