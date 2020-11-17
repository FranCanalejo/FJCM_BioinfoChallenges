# Classes required
require './GeneInf.rb'
require './InteractionNetwork.rb'
require 'rest-client'

# Function to fetch from URLs, taken from class
def fetch(url, headers = {accept: "*/*"}, user = "", pass="")
    response = RestClient::Request.execute({
      method: :get,
      url: url.to_s,
      user: user,
      password: pass,
      headers: headers})
    return response
    
    rescue RestClient::ExceptionWithResponse => e
      $stderr.puts e.inspect
      response = false
      return response  
    rescue RestClient::Exception => e
      $stderr.puts e.inspect
      response = false
      return response  
    rescue Exception => e
      $stderr.puts e.inspect
      response = false
      return response  
end

# An array with the gene list from the txt file is created
gene_list=[]
File.open("ArabidopsisSubNetwork_GeneList.txt").each do |line|
    line.strip!
    line = line.downcase
    gene_list.append(line)
end


file = File.open("interaction_networks.txt", "w") # New file to save the results of the networks
networks = [] # An empty array for save the networks is created
for n in 0..gene_list.length-1 # A network for any gene of the list will be created
    puts "n=#{n}/#{gene_list.length-1}" # Puts the counter
    already_in_net = false
    if networks.length > 0
        for net in networks
            for id in net.genes_ids
                if gene_list[n] == id
                    already_in_net = true
                end
                break if already_in_net
            end
            break if already_in_net
        end
    end
    next if already_in_net
    genes = [] # Empty array for save the a gene from the list and the genes that interacts with it
    genes.append(GeneInf.new(gene_list[n].downcase)) # GeneInf object is created for the gene
    id_list = [] # Empty array for save the IDs of the genes
    i = 0
    limit = 200 # Limit of genes for the network and for the id_list. As there are less than 200 genes in each subnetwork, the paper said, 200 would be a good limit for a depth analysis
    genes.each do |gene|
        i += 1 # Counter so the loop could be stopped
        puts "i=#{i}/#{limit}" # Puts counter
        res = fetch("http://togows.org/entry/ebi-uniprot/#{gene.gene_id}") # Look for uniprot information
        if res
            info = res.body.split("\n")
            info.each do |line|
                if gene.prot_id.empty? # Protein IDs from first result are added is that information is empty
                    if line =~ /^AC(.+)/
                        prot_name = $1.strip
                        prot_name = prot_name.split(";")
                        prot_name.each do |name|
                            name.strip!
                            gene.add_prot(name) # Protein names related to the gene are saved into the object
                        end
                    end
                end
                if line =~ /(GO:\d+);.P:(.+);/
                    gene.add_go($1, $2) # GO terms related to biological function are saved into the object
                end
            end
        end
        res = fetch("http://togows.org/entry/kegg-genes/ath:#{gene.gene_id}/pathways") # Look for metabolic pathways in kegg
        if res
            info = res.body.split("\t")
            info.each do |line|
                if line =~ /(ath\d+)\s(.+)/
                gene.add_path($1, $2.strip) # Metabolic pathways are saved
                end
            end
        end
        res = fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/query/#{gene.gene_id}?format=tab25") # Look for interactions
        if res
            a = res.body.split("\n")
            a.each do |line|
                if line =~ /^uniprotkb:(\w+)\tuniprotkb:(\w+)\ttair:(at\dg\d+)\ttair:(at\dg\d+)\t.+taxid:(3702)\ttaxid:(3702)\t.+intact-miscore:(.+)$/i
                    score = $7.to_f 
                    if ($5 == $6 && score >= 0.9) # Filter: necessary same taxid for both interacting genes/proteins and intact-miscore >= 0.9
                        if gene.gene_id.downcase == $3.downcase # Conditional to get the id for the gene that interacts with our gene
                            gene.add_prot($1.upcase) # Protein is added to the gene information
                            gene.interacts($1.upcase, $2.upcase)
                            # Add to the id_list the gene unless it was already in the list or the list has the limit length 
                            id_list.append(gene.gene_id.downcase) unless (id_list.include?(gene.gene_id.downcase) || id_list.length >= limit)
                            genes.append(GeneInf.new($4.downcase)) unless (id_list.include?($4.downcase) || id_list.length >= limit)
                            # Add to the id_list the genes that interacts unless they were already in the list or the list has the limit length 
                            id_list.append($4.downcase)
                        # Same here but for the other conditional
                        elsif gene.gene_id.downcase == $4.downcase
                            gene.add_prot($2.upcase)
                            gene.interacts($2.upcase, $1.upcase)
                            id_list.append(gene.gene_id.downcase) unless (id_list.include?(gene.gene_id.downcase) || id_list.length >= limit)
                            genes.append(GeneInf.new($3.downcase))  unless (id_list.include?($3.downcase) || id_list.length >= limit)
                            id_list.append($3.downcase)
                        end
                    end
                end
            end
        end
        break if i >= limit
    end
    if genes.length >= 2 # Create a network if there are at least 2 genes in the list (they interact between them)
        networks.append(InteractionNetwork.new(genes)) # Network is added to the array of networks
        file.write("Network #{networks.length}:\n")
        text = networks[networks.length-1].in_network(gene_list)
        puts text
        file.write("#{text}\n")
        networks[networks.length-1].prot_network.each do |key, value| # Loop for searching direct interactions from network
            next unless gene_list.include?(key)
            value.each do |k, v|
                v.each do |p_v|
                    networks[networks.length-1].prot_network.each do |key2, value2|
                        value2.each do |k2, v2|
                            if p_v == k2 && gene_list.include?(key2)
                                if key == key2
                                    t1 = "Interaction: Protein #{k} from gene #{key} #{networks[networks.length-1].go_gene[key]} #{networks[networks.length-1].pathway_gene[key]} interacts with itself\n"
                                    puts t1
                                    file.write("#{t1}")
                                else
                                    t1 = "Interaction: Protein #{k} from gene #{key} #{networks[networks.length-1].go_gene[key]} #{networks[networks.length-1].pathway_gene[key]} interacts with protein #{k2} from gene #{key2} #{networks[networks.length-1].go_gene[key2]} #{networks[networks.length-1].pathway_gene[key2]}\n"
                                    puts t1
                                    file.write("#{t1}")
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
file.close

### The results of this analysis show interaction networks related to different metabolic pathways 
### There are interaction networks related to sugar metabolism, aminoacid metabolism, RNA synthesis, photosynthesis, redox, DNA replication, lipid, metabolism...
### It should be expected, if these genes are co-expressed, that they have related functions, but they are very diverse
### It should be also expected that most of these genes would be part of the same networks. However, the networks obtained are related with
### just 10 genes from the list at most
### There are only 17 protein-protein interactions of genes from the list, and 9 of those interactions are with proteins with themselves
### Therefore, the information from the paper is not reliable, as the genes analysed are part of different networks with different functions