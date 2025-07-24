package nlp;

/**
 * 単語とその出現回数を保持する基本クラス。
 */
class WordCount {
    private Word word; // 単語オブジェクト
    private Integer count; // 出現回数

    public WordCount(Word word, Integer count) {
        this.word = word;
        this.count = count;
    }

    // 以下、getterおよびsetter
    public Word getWord() {
        return word;
    }

    public void setWord(Word word) {
        this.word = word;
    }

    public Integer getCount() {
        return count;
    }

    public void setCount(Integer count) {
        this.count = count;
    }
}

/**
 * TF(Term Frequency)の値を保持するクラス。
 */
class TfCount extends WordCount {
    private Double tf; // TF値

    public TfCount(Word word, Integer count, Double tf) {
        super(word, count);
        this.tf = tf;
    }

    // 以下、getterおよびsetter
    public Double getTf() {
        return tf;
    }

    public void setTf(Double tf) {
        this.tf = tf;
    }
}

/**
 * DF(Document Frequency)とIDF(Inverse Document Frequency)の値を保持するクラス。
 */
class DfCount extends WordCount {
    private Double idf; // IDF値
    private Integer df; // DF値 (その単語が出現した文書数)

    public DfCount(Word word, Integer count, Double idf, Integer df) {
        super(word, count);
        this.idf = idf;
        this.df = df;
    }

    // 以下、getterおよびsetter
    public Double getIdf() {
        return idf;
    }

    public void setIdf(Double idf) {
        this.idf = idf;
    }

    public Integer getDf() {
        return df;
    }

    public void setDf(Integer df) {
        this.df = df;
    }
}

/**
 * TF-IDFの計算結果を保持するクラス。
 */
class tfIdfCount extends WordCount {
    private Double tfidf; // TF-IDF値
    private Double tf; // TF値
    private Double idf; // IDF値

    public tfIdfCount(Word word, Integer count, Double tf, Double idf, Double tfidf) {
        super(word, count);
        this.tfidf = tfidf;
        this.tf = tf;
        this.idf = idf;
    }

    // 以下、getterおよびsetter
    public Double getTfidf() {
        return tfidf;
    }

    public void setTfidf(Double tfidf) {
        this.tfidf = tfidf;
    }

    public Double getTf() {
        return tf;
    }

    public void setTf(Double tf) {
        this.tf = tf;
    }

    public Double getIdf() {
        return idf;
    }

    public void setIdf(Double idf) {
        this.idf = idf;
    }
}