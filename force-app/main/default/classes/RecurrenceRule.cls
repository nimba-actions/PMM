public with sharing class RecurrenceRule {
    // some examples
    // FREQ=DAILY;INTERVAL=3;UNTIL=20200925T000000Z
    // FREQ=WEEKLY;INTERVAL=1;BYDAY=SU,MO,TU,WE,TH,FR,SA;UNTIL=20200925T000000Z
    // FREQ=WEEKLY;INTERVAL=1;BYDAY=SU,MO,TU,WE,TH,FR,SA;COUNT=10
    // FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;COUNT=12

    public enum Frequency {
        DAILY
    }

    public enum Day {
        SU,
        MO,
        TU,
        WE,
        TH,
        FR,
        SA
    }

    @TestVisible
    private String rRule;
    private Frequency freq;
    private Integer interval = 1;
    private Date endDate;
    private Integer count;
    private List<Day> days;

    public RecurrenceRule reset() {
        rRule = null;
        freq = null;
        interval = 1;
        endDate = null;
        count = null;
        days = null;
        return this;
    }

    public RecurrenceRule withFrequency(Frequency freq) {
        this.freq = freq;
        return this;
    }

    public RecurrenceRule withFrequency(String freqString) {
        setFreqFromString(freqString);
        return this;
    }

    public RecurrenceRule withInterval(Integer interval) {
        this.interval = interval;
        return this;
    }

    public RecurrenceRule withEndDate(Date endDate) {
        this.endDate = endDate;
        return this;
    }

    public RecurrenceRule withCount(Integer count) {
        this.count = count;
        return this;
    }

    public RecurrenceRule withDays(List<Day> days) {
        this.days = days;
        return this;
    }

    public RecurrenceRule withDays(List<Integer> days) {
        populateDays(days);
        return this;
    }

    public RecurrenceRule withRuleString(String rrString) {
        parseAndValidate(rrString);
        this.rRule = rrString;
        return this;
    }

    public Frequency getFrequency() {
        return freq;
    }

    public Integer getInterval() {
        return interval;
    }

    public Date getEndDate() {
        return endDate;
    }

    public Integer getCount() {
        return count;
    }

    public List<Day> getDays() {
        return days;
    }

    public String build() {
        List<String> ruleParts = new List<String>();

        // FREQ (required)
        ruleParts.add('FREQ=' + freq);

        // INTERVAL
        if (interval != 1) {
            ruleParts.add('INTERVAL=' + interval);
        }

        // UNTIL
        if (endDate != null) {
            String endDateString = DateTime.newInstanceGMT(
                    endDate,
                    Time.newInstance(0, 0, 0, 0)
                )
                .formatGmt('yyyyMMdd');

            ruleParts.add('UNTIL=' + endDateString + 'T000000Z');
        }

        // COUNT
        if (count != null) {
            ruleParts.add('COUNT=' + count);
        }

        // BYDAY
        if (days != null && days.size() > 0) {
            List<String> dayStrings = new List<String>();
            for (Day day : days) {
                dayStrings.add(day.name());
            }
            ruleParts.add('BYDAY=' + String.join(dayStrings, ','));
        }

        rRule = String.join(ruleParts, ';');
        return rRule;
    }

    private void parseAndValidate(String rRuleString) {
        List<String> ruleParts = rRuleString.split(';');

        for (String part : ruleParts) {
            List<String> thisPart = part.split('=');

            if (!thisPart.isEmpty()) {
                String thisKey = thisPart[0].toUpperCase();
                String thisValue = thisPart[1];

                switch on thisKey {
                    when 'FREQ' {
                        setFreqFromString(thisValue);
                    }
                    when 'INTERVAL' {
                        interval = Integer.valueOf(thisValue);
                    }
                    when 'UNTIL' {
                        Integer year = Integer.valueOf(thisValue.left(4));
                        Integer month = Integer.valueOf(thisValue.mid(4, 2));
                        Integer day = Integer.valueOf(thisValue.mid(6, 2));
                        endDate = Date.newInstance(year, month, day);
                    }
                    when 'COUNT' {
                        count = Integer.valueOf(thisValue);
                    }
                    when 'BYDAY' {
                        List<String> dayStrings = thisValue.split(',');
                        days = new List<Day>();
                        for (Day day : Day.values()) {
                            if (dayStrings.contains(day.name())) {
                                days.add(day);
                            }
                        }
                    }
                    when else {
                        reset();
                        throw new RecurrenceRuleException('Invalid RRule Key');
                    }
                }
            }
        }
    }

    private void setFreqFromString(String freqString) {
        for (Frequency frequency : Frequency.values()) {
            if (frequency.name() == freqString.toUpperCase()) {
                freq = frequency;
                break;
            }
        }
        if (freq == null) {
            throw new RecurrenceRuleException('Invalid frequency type.');
        }
    }

    private void populateDays(List<Integer> dayNums) {
        List<Day> daysToAssign = new List<Day>();
        List<Day> dayValues = Day.values();

        for (Integer dayNum : dayNums) {
            if (dayNum <= dayValues.size()) {
                // Expecting the day num value to start at 1; Su-Sa => 1-7
                daysToAssign.add(Day.values()[dayNum - 1]);
            } else {
                throw new RecurrenceRuleException('Invalid day number.');
            }
        }

        days = daysToAssign;
    }

    public class RecurrenceRuleException extends Exception {
    }
}