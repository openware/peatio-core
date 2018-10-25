describe Peatio::Security::KeyGenerator do
  context "generate key pair" do 
    let(:key_pair) { Peatio::Security::KeyGenerator.new.keypair_gen} 
    
    it "should generate a public private rsa key pair" do
        expect(key_pair.private).to include "-----BEGIN RSA PRIVATE KEY-----"
        expect(key_pair.public).to include OpenSSL::PKey::RSA.new(key_pair.private).public_key.to_pem
    end
  end

  context "сheck file content" do
    before do
      Peatio::Security::KeyGenerator.new.save
    end
    let(:file_for_private_key) { 'secrets/rsa-key' }
    let(:file_for_public_key) { 'secrets/rsa-key.pub' }

    let(:private_key) { File.read(file_for_private_key) }
    let(:public_key) { File.read(file_for_public_key) }

    it "should save private rsa key to the file" do
      expect(private_key).to include "-----BEGIN RSA PRIVATE KEY-----"
    end

    it "should save public key to the file" do
      expect(public_key.to_s).to include "-----BEGIN PUBLIC KEY-----"
    end
  end
end
