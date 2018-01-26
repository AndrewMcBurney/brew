require "os/mac/store/store"

describe Store do
  subject { Store.new(double("Fake database", db: "db", name: "name")) }

  describe "#update!" do
    it "should be abstract" do
      expect { subject.update!(nil) }
        .to raise_error(NotImplementedError)
    end
  end

  describe "#fetch" do
    it "should be abstract" do
      expect { subject.fetch(nil) }
        .to raise_error(NotImplementedError)
    end
  end

  describe "#flush_condition" do
    it "should be abstract" do
      expect { subject.flush_condition }
        .to raise_error(NotImplementedError)
    end
  end

  describe "#flush_cache!" do
    it "should be abstract" do
      expect { subject.flush_cache! }
        .to raise_error(NotImplementedError)
    end
  end
end
