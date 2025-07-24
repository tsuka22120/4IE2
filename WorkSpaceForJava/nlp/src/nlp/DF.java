package nlp;

import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;

/**
 * DF(Document Frequency)でソートするための比較クラス。
 */
class DfComparator implements Comparator<DfCount> {
    @Override
    public int compare(DfCount o1, DfCount o2) {
        return Integer.compare(o2.getDf(), o1.getDf()); // 降順ソート
    }
}

/**
 * DFとIDFを計算するクラス。
 */
public class DF {
    ArrayList<DfCount> list = new ArrayList<>(); // ソート・出力用のリスト
    Map<String, DfCount> map = new HashMap<>(); // 単語(原形)をキーにしたDF情報格納用マップ
    TF tf[]; // 全文書のTF計算結果

    DF(TF[] tf) {
        this.tf = tf;
    }

    /**
     * DFとIDFを計算し、ファイルに出力するメソッド。
     * 
     * @param outputFilename 出力ファイル名
     */
    public void df(String outputFilename) {
        final int N = tf.length; // 全文書数

        // --- ステップ1：DF（文書頻度）のカウント ---
        // 各文書をループし、どの単語がいくつの文書に出現したかを数える
        for (int i = 0; i < N; i++) {
            HashSet<String> uniqueWordsInDoc = new HashSet<>(); // 文書内で出現したユニークな単語を記録
            for (TfCount tfCount : tf[i].list) {
                String key = tfCount.getWord().getGenkei();
                if (uniqueWordsInDoc.add(key)) { // この文書で初めて出現した単語の場合
                    DfCount dfCount = map.get(key);
                    if (dfCount == null) { // 全文書を通じて初登場の単語
                        map.put(key, new DfCount(tfCount.getWord(), 0, 0.0, 1));
                    } else { // 既出の単語
                        dfCount.setDf(dfCount.getDf() + 1);
                    }
                }
            }
        }

        // --- ステップ2：IDF（逆文書頻度）の計算 ---
        // DFのカウントが完了した後、各単語のIDFを計算する
        for (DfCount dfc : map.values()) {
            double idf = Math.log10((double) N / dfc.getDf()) + 1.0;
            dfc.setIdf(idf);
            list.add(dfc); // 出力用のリストに追加
        }

        // --- ステップ3：ソートとファイル出力 ---
        list.sort(new DfComparator());
        try {
            FileWriter fw = new FileWriter(outputFilename);
            fw.write("#語\tDF\tIDF\n");
            for (DfCount dfc : list) {
                fw.write(dfc.getWord().getGenkei() + "\t" +
                        dfc.getDf() + "\t" +
                        dfc.getIdf() + "\n");
            }
            fw.close();
        } catch (IOException e) {
            e.printStackTrace();
            System.out.println("出力ファイルの書き込みに失敗しました。");
        }
    }
}