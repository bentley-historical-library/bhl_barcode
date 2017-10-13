class BHLBarcode

    def self.find_by_barcode(model, params)
        if model[params]
            model.to_jsonmodel(model[params][:id])
        else
            {:error => "#{model} not found for params #{params}"}
        end
    end

end