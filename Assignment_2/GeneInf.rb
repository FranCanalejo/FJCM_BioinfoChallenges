# Class for saving information of a gene
class GeneInf

    attr_accessor :gene_id
    attr_accessor :prot_id
    attr_accessor :go
    attr_accessor :pathway
    attr_accessor :interaction

    @@all_genes = Array.new
    @@all_prots = Hash.new{|hsh,key| hsh[key] = []}

    def initialize(arg)
        @gene_id = arg #Add the gene id
        @prot_id = Array.new # Array for add the proteins related to the traduction of that gene
        @go = Hash.new # Hash for the go term (keys are GO ID and values GO terms of biological functions)
        @pathway = Hash.new # Hash for the metabolic pathways (keys are pathways ID and values pathways names)
        @interaction = Hash.new{|hsh,key| hsh[key] = []} # Hash for protein-protein interactions related to the gene

        @@all_genes << self

    end

    def add_prot(prot)
        @prot_id.push prot unless @prot_id.include?(prot) # Add proteinID(s)
        @@all_prots[@gene_id].push prot unless @@all_prots[@gene_id].include?(prot)
    end

    def add_go(go_id, go_term)
        @go[go_id] = go_term # Add GO term
    end

    def add_path(path_id, path_name)
        @pathway[path_id] = path_name # Add pathway
    end

    def interacts(prot_gene, prot)
        @interaction[prot_gene].push prot unless @interaction[prot_gene].include?(prot) # Add protein-protein interactions
    end

    def all_prots
        return @@all_prots
    end

    def all_genes
        return @@all_genes
    end

end