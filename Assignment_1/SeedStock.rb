# Define class SeedStock and create an attribute accesor for each property
# 'csv' is required for a method in this class
require 'csv'
class SeedStock

    attr_accessor :seedID
    attr_accessor :mutant_geneID
    attr_accessor :last_planted
    attr_accessor :storage
    attr_accessor :grams
    # Initialize parameters
    def initialize (params={})
        @seedID = params.fetch(:seedID, "0000")
        @mutant_geneID = params.fetch(:mutant_geneID, "AT0G00000")
        @last_planted = params.fetch(:last_planted, "unknown")
        @storage = params.fetch(:storage, "unknown")
        @grams = params.fetch(:grams, "unknown")
    end

    # Method for return parameters if the seedID is found 
    def get_seed_stock(text)
        if @seedID == text
            return "#{@seedID}\t#{@mutant_geneID}\t#{@last_planted}\t#{@storage}\t#{@grams}"
        else
            return false
        end
    end

    # Method for simulate planting 7g of each seed
    def plant7g
        # Conditional the method will only work if grams is not a string or nil
        # It is done in case no grams value is introduced. In that case the value
        # will be "unknown" and this method will do nothing
        if @grams !~ /\w/ && @grams != nil
            @grams = @grams-7
            # Attribute last_planted is update to current date
            @last_planted = DateTime.now.strftime("%d/%m/%Y")
            # If grams is less than 7, they will be simulated planted and the value
            # will be set 0. Also a warning message that there is no more stock will
            # be printed
            if @grams <= 0
                @grams = 0
                puts "WARNING: we have run out of Seed Stock #{@seedID}"
            end
        else
            # Because of the conditional, if grams is string or nil an error will be
            # printed as stderr
            $stderr.puts "ERROR: #{@grams} not integer"
        end
    end

    # Method fo write the database
    def write_database(new_stock_file)
        # If the database name introduced doesn't exist, the method will create one
        # and a header will be added with the attibute names
        # Separator is tab
        if File.exist?(new_stock_file) == false
            CSV.open(new_stock_file, 'wb', col_sep: "\t") do |tsv|
                header = ["Seed_Stock","Mutant_Gene_ID","Last_Planted","Storage","Grams_Remaining"]
                tsv << header
            end
        end
        # If the database name exists,the values of the object will be added
        # Separator is tab
        CSV.open(new_stock_file, 'ab', col_sep: "\t") do |tsv|
            # With this conditional, in case the mutant_geneID were another
            # object of Class Gene, the geneID will be taken from it
            if @mutant_geneID.class == Gene
                geneID = @mutant_geneID.geneID
            else
                geneID = @mutant_geneID
            end
            text_to_add = [@seedID,geneID,@last_planted,@storage,@grams]
            tsv << text_to_add
        end
    end
end