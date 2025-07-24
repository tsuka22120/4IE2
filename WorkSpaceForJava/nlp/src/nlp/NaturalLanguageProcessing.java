//javac -d bin src/nlp/*.java
//java -cp bin nlp.NaturalLanguageProcessing
package nlp;

/**
 * 自然言語処理のメインクラス。
 * 複数のテキストファイルに対してTF, DF, TF-IDFの計算を順次実行する。
 */
public class NaturalLanguageProcessing {
    // プログラムのエントリーポイント
    static public void main(String args[]) {
        // 100個のTFオブジェクトを格納する配列を準備
        TF[] tf = new TF[100];

        // 100個のテキストファイルそれぞれに対してTF(Term Frequency)を計算
        for (int i = 1; i <= 100; i++) {
            tf[i - 1] = new TF();
            // 入力ファイル名と出力ファイル名を生成
            String inputFileName = "./data/" + String.format("%03d", i) + ".txt";
            String outputFileName = "./out/" + String.format("%03d", i) + "tf.txt";
            tf[i - 1].tf(inputFileName, outputFileName);
        }
        System.out.println("TF 導出完了");

        // 全てのTFの結果を用いてDF(Document Frequency)とIDF(Inverse Document Frequency)を計算
        DF df = new DF(tf);
        System.out.println("DF 導出完了");
        df.df("./out/df.txt");

        // 各文書について、TFとIDFを組み合わせてTF-IDFを計算
        for (int i = 1; i <= 100; i++) {
            String outputFileName = "./out/" + String.format("%03d", i) + "tfidf.txt";
            TF_IDF tfIdf = new TF_IDF(tf[i - 1], df);
            tfIdf.tfIdf(outputFileName);
        }
        System.out.println("処理が完了しました");
    }
}