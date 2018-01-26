require "os/mac/database/linkage_database"

describe LinkageDatabase do
  subject { LinkageDatabase.new }

  describe "#create_tables" do
    it "should be concrete" do
      expect { subject.create_tables }
        .to_not raise_error(NotImplementedError)
    end
  end
end
