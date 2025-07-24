package nlp;

import java.util.Objects;

/**
 * 形態素解析結果の単語情報を保持するクラス。
 */
public class Word {
    private String hyousoukei; // 表層形 (実際に文中に現れた形)
    private String hinshi; // 品詞
    private String hinshi1; // 品詞細分類1
    private String hinshi2; // 品詞細分類2
    private String hinshi3; // 品詞細分類3
    private String katsuyoKata;// 活用方
    private String katsuyoKei; // 活用形
    private String genkei; // 原形 (基本形)
    private String yomi; // 読み
    private String hatsuon; // 発音

    // 以下、各フィールドのgetterおよびsetter
    public String getHyousoukei() {
        return hyousoukei;
    }

    public void setHyousoukei(String hyousoukei) {
        this.hyousoukei = hyousoukei;
    }

    public String getHinshi() {
        return hinshi;
    }

    public void setHinshi(String hinshi) {
        this.hinshi = hinshi;
    }

    public String getHinshi1() {
        return hinshi1;
    }

    public void setHinshi1(String hinshi1) {
        this.hinshi1 = hinshi1;
    }

    public String getHinshi2() {
        return hinshi2;
    }

    public void setHinshi2(String hinshi2) {
        this.hinshi2 = hinshi2;
    }

    public String getHinshi3() {
        return hinshi3;
    }

    public void setHinshi3(String hinshi3) {
        this.hinshi3 = hinshi3;
    }

    public String getKatsuyoKata() {
        return katsuyoKata;
    }

    public void setKatsuyoKata(String katsuyoKata) {
        this.katsuyoKata = katsuyoKata;
    }

    public String getKatsuyoKei() {
        return katsuyoKei;
    }

    public void setKatsuyoKei(String katsuyoKei) {
        this.katsuyoKei = katsuyoKei;
    }

    public String getGenkei() {
        return genkei;
    }

    public void setGenkei(String genkei) {
        this.genkei = genkei;
    }

    public String getYomi() {
        return yomi;
    }

    public void setYomi(String yomi) {
        this.yomi = yomi;
    }

    public String getHatsuon() {
        return hatsuon;
    }

    public void setHatsuon(String hatsuon) {
        this.hatsuon = hatsuon;
    }

    /**
     * オブジェクトが等価であるかを判定する。
     * 全てのフィールドが一致する場合にtrueを返す。
     */
    @Override
    public boolean equals(Object obj) {
        if (obj == null || !(obj instanceof Word))
            return false;
        Word other = (Word) obj;
        return (safeEquals(hyousoukei, other.hyousoukei)
                && safeEquals(hinshi, other.hinshi)
                && safeEquals(hinshi1, other.hinshi1)
                && safeEquals(hinshi2, other.hinshi2)
                && safeEquals(hinuyoKei, other.katsuyoKei)
                && safeEquals(genkeshi3, other.hinshi3)
                && safeEquals(katsuyoKata, other.katsuyoKata)
                && safeEquals(katsi, other.genkei)
                && safeEquals(yomi, other.yomi)
                && safeEquals(hatsuon, other.hatsuon));
    }

    // nullを安全に扱うための文字列比較ヘルパーメソッド
    private boolean safeEquals(String s1, String s2) {
        if (s1 == null && s2 == null)
            return true;
        if (s1 == null || s2 == null)
            return false;
        return s1.equals(s2);
    }
}