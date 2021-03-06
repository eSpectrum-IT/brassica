class Analysis
  module Gwas
    module Helpers
      def genotype_data_file(type = nil)
        scope = analysis.data_files.gwas_genotype
        scope = scope.send(type) if type
        scope.generated.first || scope.uploaded.first
      end

      def phenotype_data_file
        scope = analysis.data_files.gwas_phenotype
        scope.generated.first || scope.uploaded.first
      end

      def map_data_file
        scope = analysis.data_files.gwas_map
        scope.generated.first || scope.uploaded.first
      end

      def normalize_csv(*args)
        Analysis::CsvNormalizer.new.call(*args)
      end

      def normalize_geno_csv(geno_csv_file = genotype_data_file(:csv).file)
        normalize_csv(geno_csv_file, remove_columns: analysis.meta['removed_mutations'])
      end

      def normalize_pheno_csv(pheno_csv_file = phenotype_data_file.file)
        normalize_csv(pheno_csv_file, normalize_first_row: true, remove_columns: analysis.meta['removed_traits'])
      end

      def create_csv_data_file(file, data_type:)
        analysis.data_files.create!(
          role: :input,
          origin: :generated,
          data_type: data_type,
          file: file,
          file_content_type: "text/csv",
          owner: analysis.owner
        )
      end

      # Scans the file and returns:
      #
      # * Headers of columns for which there is less than two distinct
      # values (NA does not count). Such columns cannot be passed as input
      # for GWASSER.
      # * Elements of first column (except "ID").
      #
      # TODO: this could initially be done by CsvNormalizer itself saving
      # one pass through csv file
      def analyze_csv_file(csv_file)
        values_by_col_name = Hash.new { |h, k| h[k] = Set.new }
        row_names = []

        CSV.open(csv_file.path) do |csv|
          headers = csv.readline

          csv.each do |row|
            row.each.with_index do |val, col_idx|
              values_by_col_name[headers[col_idx]] << val
              row_names << val if col_idx == 0
            end
          end
        end

        col_names_to_remove = values_by_col_name.
          select { |col_name, values| (values - ["NA"]).size < 2 }.
          keys - ["ID"]

        [col_names_to_remove, row_names]
      end

      def analyze_geno_csv_file(geno_csv_file = genotype_data_file(:csv).file)
        analyze_csv_file(geno_csv_file).tap do |metadata|
          if block_given?
            yield(metadata)
          else
            save_genotype_metadata(removed_mutations: metadata[0], samples: metadata[1])
          end
        end
      end

      def analyze_pheno_csv_file(pheno_csv_file = phenotype_data_file.file)
        analyze_csv_file(pheno_csv_file).tap do |metadata|
          block_given? ? yield(metadata) : save_phenotype_metadata(removed_traits: metadata[0], samples: metadata[1])
        end
      end

      def save_genotype_metadata(removed_mutations: nil, samples: nil, chromosomes: nil)
        analysis.meta['removed_mutations'] = removed_mutations if removed_mutations
        analysis.meta['geno_samples'] = samples if samples
        analysis.meta['chromosomes'] = chromosomes if chromosomes
        analysis.save!
      end

      def save_phenotype_metadata(removed_traits: nil, samples: nil)
        analysis.meta['removed_traits'] = removed_traits.map { |trait| trait.gsub(/\W/, '_') } if removed_traits
        analysis.meta['pheno_samples'] = samples if samples
        analysis.save!
      end

      def append_genotype_metadata(removed_mutations: nil)
        analysis.meta['removed_mutations'] += removed_mutations if removed_mutations
        analysis.save!
      end

      def append_phenotype_metadata(removed_traits: nil)
        analysis.meta['removed_traits'] += removed_traits.map { |trait| trait.gsub(/\W/, '_') } if removed_traits
        analysis.save!
      end
    end
  end
end
