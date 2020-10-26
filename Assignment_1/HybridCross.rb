# Define class HybridCross and create an attribute accesor for each property
class HybridCross

    attr_accessor :parent1
    attr_accessor :parent2
    attr_accessor :f2_wild
    attr_accessor :f2_p1
    attr_accessor :f2_p2
    attr_accessor :f2_p1p2

    # Define initialize parameters
    def initialize(params={})
        @parent1 = params.fetch(:parent1)
        @parent2 = params.fetch(:parent2)
        @f2_wild = params.fetch(:f2_wild)
        @f2_p1 = params.fetch(:f2_p1)
        @f2_p2 = params.fetch(:f2_p2)
        @f2_p1p2 = params.fetch(:f2_p1p2)
    end

    # Method for gettting chisquare value in an object
    # Because of the initialize attributes it is understood that
    # this class is for a dihybrid cross
    def chisquare_test
        total = Float(@f2_wild + @f2_p1 + @f2_p2 + @f2_p1p2)
        f2_wild = @f2_wild.to_f
        f2_p1 = @f2_p1.to_f
        f2_p2 = @f2_p2.to_f
        f2_p2p1 = @f2_p2p1.to_f
        @chisquare = ((f2_wild-9*total/16)**2)/(9*total/16)\
        + ((f2_p1-3*total/16)**2)/(3*total/16)\
        + ((f2_p2-3*total/16)**2)/(3*total/16)\
        + ((f2_p1p2-1*total/16)**2)/(1*total/16)
        # Chisquare value is calculated for a dihybridcross
        # In this type of cross, degree of freedom is 3
        # For a degree of freedom of 3, if chisquare is equal or greater
        # than 7.815 is statistically significant
        # In that case method will record the linked genes
        if @chisquare >= 7.815
            # In case attribute 'parent1' were SeedStock object with Gene object
            # p1 value would be the Gene name from Gene object
            if @parent1.class == SeedStock && @parent1.mutant_geneID.class == Gene
                p1 = @parent1.mutant_geneID.name
                # In that case, if 'parent2' has the same structure, the link method
                # from the Gene object is called and the Gene name from parent2 is
                # recorded
                if @parent2.class == SeedStock && @parent2.mutant_geneID.class == Gene
                    @parent1.mutant_geneID.link(@parent2.mutant_geneID.name)
                # If 'parent2' is a SeedStock object with no Gene object, mutant_geneID
                # from SeedStock object is recorded
                elsif @parent2.class == SeedStock
                    @parent1.mutant_geneID.link(@parent2.mutant_geneID)
                # If 'parent2' is not an object, just that attribute will be recorded
                else
                    @parent1.mutant_geneID.link(@parent2)
                end
            # If 'parent1' is a SeedStock object with no Gene object, p1 is equal to
            # mutant_geneID from SeedStock object
            elsif @parent1.class == SeedStock
                p1 = @parent1.mutant_geneID
            # In other cases, p1 i just 'parent1'
            else
                p1 = @parent1
            end
            # Exactly the same is done for attribute 'parent2'
            if @parent2.class == SeedStock && @parent2.mutant_geneID.class == Gene
                p2 = @parent2.mutant_geneID.name
                if @parent1.class == SeedStock && @parent1.mutant_geneID.class == Gene
                    @parent2.mutant_geneID.link(@parent1.mutant_geneID.name)
                elsif @parent1.class == SeedStock
                    @parent2.mutant_geneID.link(@parent1.mutant_geneID)
                else
                    @parent2.mutant_geneID.link(@parent1)
                end
            elsif @parent2.class == SeedStock
                p2 = @parent2.mutant_geneID
            else
                p2 = @parent2
            end
            # At the end will be printed that 'p1' is genetically linked with 'p2'
            # 'p1' and 'p2' values will be different because of the code above
            puts "Recording: #{p1} is genetically linked with #{p2} with chisquare score #{@chisquare}"
        end
    end
end