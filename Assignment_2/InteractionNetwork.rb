# Class for creating an interaction network from an array of genes
class InteractionNetwork

    attr_accessor :genes
    attr_accessor :go_gene
    attr_accessor :go
    attr_accessor :pathway_gene
    attr_accessor :pathways
    attr_accessor :genes_ids
    attr_accessor :prot_network


    def initialize(genes_array)
        abort "Input must be an Array of Genes" unless genes_array.class == Array # Abort if input is not an array
        @genes = Array.new
        @genes_ids = Array.new
        @go_gene = Hash.new
        @go = Hash.new
        @pathway_gene = Hash.new
        @pathways = Hash.new
        @prot_network = Hash.new
        genes_array.each do |gene|
            next if gene == nil
            if gene.class == GeneInf
                @genes << gene # Genes are obtained from the array
                @genes_ids << gene.gene_id unless gene.gene_id == nil # Genes_ids of the genes that are part of the network are obtained
                @go_gene[gene.gene_id] = gene.go unless gene.go == nil # GO terms of each gene are saved individually in a hash
                @go = @go.merge(gene.go) unless gene.go == nil# GO terms from every gene are obtained as GO terms of the network
                @pathway_gene[gene.gene_id] = gene.pathway unless gene.pathway == nil # Pathway information of each gene is saved in a hash
                @pathways = @pathways.merge(gene.pathway) unless gene.pathway == nil # Pathways from every gene are obtained
                @prot_network[gene.gene_id] = gene.interaction unless gene.interaction == nil # Interactions are saved in a hash related to the gene ID
            else
                abort "Input must be an Array of GeneInf" # Abort if the array is not composed of GeneInf class
            end
        end
    end  

    # This function get from an array which of the genes of that array are part of the network, and all gene IDs GO terms and pathways are printed
    def in_network(list)
        abort "Input must be Array" unless list.class == Array
        g_not_list = @genes_ids - list
        g_in_net = @genes_ids - g_not_list
        if g_in_net.length >= 2
            #puts "#{g_in_net} in the same network"
            #puts "Genes involved in the network:\n#{@genes_ids}\nGO Terms: #{@go}\nPathways: #{@pathways}\n"
            return "#{g_in_net} from list in this network\nGenes involved in the network: #{@genes_ids}\nProtein interactions: #{@prot_network}\nGO Terms: #{@go}\nPathways: #{@pathways}"
        else
            #puts "There is no more than one gene in the gene list included in this network"
            return "No more than 1 gene from the list in this network"
        end
    end

    def net_info #Function to get the information of the network
        return "Genes involved in the network:\n#{@genes_ids}\nGO Terms: #{@go}\nPathways: #{@pathways}\n"
    end

end