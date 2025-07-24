package nlp;

import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Map;

/**
 * TF-IDFスコアでソートするための比較クラス。
 */
class tfIdfComparator implements Comparator<tfIdfCount> {
    @Override
    public int compare(tfIdfCount o1, tfIdfCount o2) {
        return Double.compare(o2.getTfidf(), o1.getTfidf()); // 降順ソート
    }
}

/**
 * TF-IDFを計算するクラス。
 */
class TF_IDF {
    ArrayList<tfIdfCount> list = new ArrayList<>(); // 計算結果を格納するリスト
    TF tf; // 対象文書のTF情報
    DF df; // 全文書のDF/IDF情報

    public TF_IDF(TF tf, DF df) {
        this.tf = tf;
        this.df = df;
    }

    /**
     * TF-IDFを計算し、ファイルに出力するメソッド。
     * 
     * @param outputFilename 出力ファイル名
     */
    public void tfIdf(String outputFilename) {
        Map<String, DfCount> dfMap = df.map;

        // 文書内の各単語についてTF-IDFを計算 (TF-IDF = TF * IDF)
        for (TfCount tfCount : tf.list) {
            String genkei = tfCount.getWord().getGenkei();
            DfCount dfCount = dfMap.get(genkei); // 全文書から計算したIDF値を取得

            if (dfCount != null) {
                Double tfValue = tfCount.getTf();
                Double idfValue = dfCount.getIdf();
                Double tfIdfValue = tfValue * idfValue;
                list.add(new tfIdfCount(tfCount.getWord(), tfCount.getCount(), tfValue, idfValue, tfIdfValue));
            }
        }

        // TF-IDFスコアでソートし、ファイルに出力
        list.sort(new tfIdfComparator());
        try {
            FileWriter fw = new FileWriter(outputFilename);
            fw.write("#語\t出現回数\tTF\tIDF\tTF-IDF\t\n");
            for (tfIdfCount tfIdf : list) {
                fw.write(tfIdf.getWord().getGenkei() + "\t" + tfIdf.getCount() + "\t" +
                        tfIdf.getTf() + "\t" + tfIdf.getIdf() + "\t" + tfIdf.getTfidf() + "\n");
            }
            fw.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}