module DateHelper
    def next_quarter_start(date)
        quarter_month = ((date.month / 3.0).ceil * 3 + 1) % 12
        return DateTime.new(date.year, quarter_month, 1, 0)
    end

    def current_quarter_start(date)
        quarter_month = (((date.month - 1) / 3.0).floor * 3 + 1) % 12
        return DateTime.new(date.year, quarter_month, 1, 0)
    end
end
