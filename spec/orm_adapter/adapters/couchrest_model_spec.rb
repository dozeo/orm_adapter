require 'spec_helper'
require 'orm_adapter/example_app_shared'

$couch_url = "http://127.0.0.1:5984/orm_adapter_spec" # for when the couch db doesn't have a password on it
# $couch_url = "http://admin:admin@127.0.0.1:5984/orm_adapter_spec"

if !defined?(CouchRest::Model)
  puts "** require 'couchrest_model' to run the specs in #{__FILE__}"
elsif !(CouchRest.database!($couch_url) rescue nil)
  puts "** start CouchDB to run the specs in #{__FILE__}"
else  
  
  module CouchrestModelOrmSpec

    class User < CouchRest::Model::Base
      use_database CouchRest.database!($couch_url)

      property :name
      view_by :name
      collection_of :notes#, :class_name => 'Note'
      # collection_of :notes, CouchrestModelOrmSpec::Note
    end

    class Note < CouchRest::Model::Base
      use_database CouchRest.database!($couch_url)

      property :body, :default => "made by orm"
      belongs_to :user, CouchrestModelOrmSpec::User
      # belongs_to :owner, CouchrestModelOrmSpec::User
      # belongs_to :owner, class_name: 'User'
      view_by :owner_id
      def self.by_owner(options)
        options = options.dup
        options[:key] = options[:key].id
        self.by_owner_id(options)
      end
    end

    # here be the specs!
    describe CouchRest::Model::Base::OrmAdapter do
      before do
        User.delete_all
        Note.delete_all
      end

      describe "the OrmAdapter class" do
        subject { CouchRest::Model::Base::OrmAdapter }

        specify "#model_classes should return all document classes" do
          (subject.model_classes & [User, Note]).to_set.should == [User, Note].to_set
        end
      end

      it_should_behave_like "example app with orm_adapter" do
        let(:user_class) { User }
        let(:note_class) { Note }
      end
    end
  end
end
