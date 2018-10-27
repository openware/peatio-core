describe Peatio::Security::KeyGenerator do
  context "generate key pair" do 
    let(:key_pair) { Peatio::Security::KeyGenerator.new}
    
    it "should generate a public private rsa key pair" do
        expect(key_pair.private).to include "-----BEGIN RSA PRIVATE KEY-----"
        expect(OpenSSL::PKey::RSA.new(key_pair.public).public?).to be true
    end
  end

  context "сheck file content" do
    before do
      Peatio::Security::KeyGenerator.new.save("secrets")
    end
    let(:file_for_private_key) { 'secrets/rsa-key' }
    let(:file_for_public_key) { 'secrets/rsa-key.pub' }

    let(:private_key) { OpenSSL::PKey::RSA.new File.read(file_for_private_key) }
    let(:public_key) { OpenSSL::PKey::RSA.new File.read(file_for_public_key) }

    it "should save private rsa key to the file" do
      expect(private_key.private?).to be true
      expect(private_key.public_key.to_pem).to eq public_key.to_pem
    end

    it "should save public key to the file" do
      expect(public_key.to_s).to include "-----BEGIN PUBLIC KEY-----"
    end
  end
end
