# Define class Gene and create an attribute accesor for each property
class Gene

    attr_accessor :geneID
    attr_accessor :name
    attr_accessor :phenotype
    attr_accessor :linked

    # Define initialize parameters
    def initialize (params = {})
        # My policy is that if no geneID is introduced, AT0G00000 will be introduced
        # by default. As it makes no sense having chromosome 0, it means it is unknown,
        # but the code won't break with de geneID validation (we'll see now)
        @geneID = params.fetch(:geneID, "AT0G00000")
        @name = params.fetch(:name, "unknown")
        @phenotype = params.fetch(:phenotype, "unknown")
        # Validation for gene ID. If geneID doesn't match the format that is required
        # the code will break with a stderr message (abort puts as stderr and stop
        # the code at the same time)
        if @geneID !~ /^A[Tt]\d[Gg]\d{5}$/
            abort "#{@geneID} => Incorrect gene ID format"
        end
    end

    # Method for searching geneID or name in an object
    # It returns geneID, name and phenotype
    def get_gene(text)
        if @geneID == text || @name == text
            return "#{@geneID}\t#{@name}\t#{@phenotype}"
        else
            return false
        end
    end

    # Method that create attribute linked.
    # It should indicate if the object (of class Gene) is linked with another gene
    def link(gene_name)
        @linked = gene_name
    end

end
