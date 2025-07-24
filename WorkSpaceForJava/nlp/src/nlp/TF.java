package nlp;

import java.io.BufferedReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;

/**
 * WordCountオブジェクトを出現回数でソートするための比較クラス。
 */
class WordCompare implements Comparator<WordCount> {
    @Override
    public int compare(WordCount wc1, WordCount wc2) {
        return Integer.compare(wc2.getCount(), wc1.getCount()); // 降順ソート
    }
}

/**
 * TF(Term Frequency)を計算するクラス。
 */
public class TF {
    Map<String, TfCount> map = new HashMap<>(); // 単語(原形)をキーにしたTF情報格納用マップ
    ArrayList<TfCount> list = new ArrayList<TfCount>(); // ソート・出力用のリスト

    /**
     * MeCabを使って形態素解析を行い、TFを計算してファイルに出力する。
     * 
     * @param inputFilename  入力テキストファイル
     * @param outputFilename TF値を出力するファイル
     */
    public void tf(String inputFilename, String outputFilename) {
        try {
            FileWriter fw = new FileWriter(outputFilename);

            // MeCabを外部コマンドとして実行
            String[] command = { "cmd.exe", "/C", "mecab", inputFilename };
            Process ps = Runtime.getRuntime().exec(command);

            // MeCabの実行結果をSJISで読み込む
            BufferedReader bReader_i = new BufferedReader(new InputStreamReader(ps.getInputStream(), "SJIS"));
            String targetLine;
            this.list.clear();

            // MeCabの出力を行単位で読み込み、単語を抽出
            while ((targetLine = bReader_i.readLine()) != null) {
                if (targetLine.equals("EOS"))
                    continue; // End of Sentenceはスキップ

                String[] targetArray = targetLine.split("[,\t]");
                Word wo = new Word();

                // MeCabの出力フォーマットに従って単語情報をパース
                if (targetArray.length >= 2) {
                    wo.setHyousoukei(targetArray[0]);
                    wo.setHinshi(targetArray[1]);
                    // 名詞、動詞、形容詞以外は除外
                    if (!wo.getHinshi().equals("名詞") && !wo.getHinshi().equals("動詞") && !wo.getHinshi().equals("形容詞")) {
                        continue;
                    }
                }
                if (targetArray.length >= 8) {
                    wo.setGenkei(targetArray[7]);
                    // ストップワード(一般的すぎて特徴語になりにくい単語)を除外
                    if (wo.getGenkei().equals("する") || wo.getGenkei().equals("ある") ||
                            wo.getGenkei().equals("こと") || wo.getGenkei().equals("*")) {
                        continue;
                    }
                }

                // ここでは最終的に名詞のみを対象とする
                if (wo.getHinshi() != null && !wo.getHinshi().equals("名詞")) {
                    continue;
                }

                // 単語の出現回数をカウント
                String key = wo.getGenkei();
                if (key == null)
                    continue;
                TfCount tfCount = map.get(key);
                if (tfCount == null) { // 初めて出現した単語
                    map.put(key, new TfCount(wo, 1, 0.0));
                } else { // 既出の単語
                    tfCount.setCount(tfCount.getCount() + 1);
                }
            }

            // TF値を計算 (TF = ある単語の出現回数 / 全単語の総数)
            int totalCount = 0;
            for (TfCount tfc : map.values()) {
                totalCount += tfc.getCount();
            }
            for (TfCount tfc : map.values()) {
                if (totalCount > 0) {
                    tfc.setTf((double) tfc.getCount() / totalCount);
                }
                this.list.add(tfc);
            }

            // 出現回数でソートしてファイルに出力
            list.sort(new WordCompare());
            fw.write("#語\t出現回数\tTF\n");
            for (TfCount tfc : list) {
                fw.write(tfc.getWord().getGenkei() + "\t" +
                        tfc.getCount() + "\t" +
                        String.format("%.10f", tfc.getTf()) + "\n");
            }
            fw.close();

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}