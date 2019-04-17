### Shortcutware ヘルプ
- Japanese version only

##### [使い方](#usage) ・ [注意事項](#notes) ・ [Utility Object Reference](#utilobj)
>  

##### はじめに

> > この度は本Chrome拡張をインストールいただきありがとうございます。  
>
> > 本拡張は、GoogleChromeの主にキーボードショートカットの機能を拡張するもので、以下の特徴・機能があります。

##### 機能紹介

> **ショートカットキーへのキーマッピング（再割り当て）機能**
>
> > ショートカットキーに、ほぼすべてのキー入力を割り当てられます。
> >
> > ショートカットキー to ショートカットキーも可能なので、Chrome標準のショートカットキー機能のキーアサインを  
> > 別のショートカットキーに割り当てることができます。 オプションで単独キーへの割り当ても可能です。  
> >
> > また、トリガーに、キー入力ではなく、コンテキストメニュー、ツールバーボタンを割り当てることもできます。  

> **拡張コマンド機能**
>
> > 次のコマンドをショートカットキーに割り当てて、ショートカットキーの機能を拡張することができます。  
> >
> > 1. 主にタブ周りの機能で、タブの移動やコピー、削除、固定、切り離し、Window選択等  
> > 2. ブラウザキャッシュ、クッキーの削除
> > 3. 定型文貼り付け  
> > 4. CSS挿入  
> > 5. JavaScript実行  
> >
> > JavaScript実行機能では、ユーティリティオブジェクトを利用して、キー入力やクリップボード、通知ウィンドウ等を操作することができます。  
> > また、jQueryとCoffeeScriptが利用できます。

> **ブックマークの割り当て・サーチ機能**
>
> > ショートカットキーにブックマークを割り当てられます。
> >
> > 既に開いている場合は、タブを検索してアクティブにできます。

> **キーボードマクロ・バッチ実行機能**
>
> > キー入力や拡張コマンド等の機能を組み合わせて、一度のショートカットキーで呼び出すことができます。  
> >  

> **マウスホイールでのタブ切り替え機能**
>
> > Linux版のChromeやChrome派生ブラウザでは実現されている、マウスホイールでのタブ切り替え機能をオプションで選択できます。  
> >  

> **コンテンツスクリプトレス**
>
> > Chrome拡張の多くは、ページ読み込み毎に一緒にスクリプトが読み込まれ、スクリプトがページに常駐する形で機能しますが（コンテンツスクリプト）  
> > 本拡張ではコンテンツスクリプトを使用しない為、通常のページ読み込みに余分な負荷をかけません。（単独キーショートカット有効時はコンテンツスクリプトを使用します）  
<br>

<a name="usage"></a>
##### オプションページの基本操作
> - **ショートカットキーの登録**
>
>  1. AddNewボタンをクリックしてからショートカットキーを押下するか、直接ショートカットキーを押下して  
>     新しく割り当てるショートカットキー（Shrotcut key）を登録します。  
> >
> >    - ファンクションキーは単独でショートカットキーになります。  
> >    - 単独キーショートカット有効時は、単独キーの登録が可能です。（Shiftキー併用可）  
> >    - この拡張のツールバーボタンをクリックすると、ツールバーボタンのショートカットキーが登録/フォーカスされます。
> >    - AddNewボタンはフォーカスが当たっている行の上に追加されます。 直接ショートカットキーを押下した場合は、常に最後に追加されます。
> >    - 既に登録済みのショートカットキーは登録できません。  
> >    - Alt+Tab、Ctrl+Esc、Win+EなどのWindowsショートカットキーは登録できません。
>
>  2. 自動的に、変更したいキー（Dest key）の入力にフォーカスされるので、任意のキーを押下して登録します。
> >
> >    - Dest keyがショートカットキーで、Chromeのショートカット機能が割り当てられている場合は、Descriptionにショートカットキーのヘルプが表示されます。
> >    - 修飾キー（Ctrl、Shift、Alt、Winキー）は単独では登録できません。
> >    - マウスイベントは登録できません。
> >    - その他、アプリケーションキーやプリントスクリーンキー、日本語入力関連のキー等、一部登録できないキーがあります。

> - **ショートカットキーの変更**
>
>    割り当てるショートカットキー(Shrotcut key)、変更したいキー(Dest key)のどちらも  
>    フォーカスが当たっている状態でキーを押下すれば変更できます。
>
>    Dest keyは重複可ですが、Shrotcut keyは登録済みのショートカットキーには変更できません。

> - **機能（Mode）の変更**
>
>    初期登録時は、Mode列に<i class="icon-random"></i>(Remap)が表示されています。  
>    マウスカーソルをあわせると<i class="icon-caret-down"></i>アイコンが表示されるので、クリックするとメニューが表示されます。
>    以下のメニューがあります。
> >
> >    <i class="icon-random"></i>**Remap** ................... ショートカットキーを別のショートカットキーに割り当てます。  
> >
> >    <i class="icon-cog"></i>**Command** .............. 拡張コマンドをショートカットキーに割り当てます。   
> > 　　　　　　　　　　　　　　　     [コマンド選択](#command)ダイアログが開き、続けて、追加オプションが必要な場合、<wbr>[拡張コマンドのオプション](#commandOptions)入力ダイアログが開きます。  
> >
> >    <i class="icon-bookmark-empty"></i>**Bookmark** .............. ブックマーク（ブックマークレット含む）をショートカットキーに割り当てます。  
> > 　　　　　　　　　　　　　　　 ブックマーク選択ダイアログが開き、ブックマークの場合は、続けて[ブックマークのオプション](#bookmarkOptions)入力ダイアログが開きます。  
> > 　　　　　　　　　　　　　　　 ブックマークレットの場合は、続けて[Inject JavaScriptのオプション](#commandOptions)入力ダイアログが開きます。  
> >
> >    <i class="icon-ban-circle"></i>**Disabled** ................. ショートカットキーを無効にして使用不可にします。  
> >
> >    <i class="icon-eye-close"></i>**Sleep** ...................... バッチ実行モード時に選択できます。  次の機能を呼び出すまでの時間（間隔）をミリ秒単位で調整します。
> >
> >    <i class="icon-comment-alt"></i>**Comment** ............... バッチ実行モード時に選択できます。 何も実行されません。 バッチのタイトルやメモ替わりに使用します。  
>
>    なお、Modeを変更すると、ブックマークの設定は消去されるので、ご注意ください。

> 以下は、各行の右端に表示されるアイコンボタン[<i class="icon-caret-down"></i>]クリック時のメニューから選択します。  
> メニュー項目は、Modeにより一部内容が異なります。
>
> - **ショートカットキーの削除**  
>    「Delete」を選択します。 復帰はできません。
> - **ショートカットキーの一時停止**  
>    「Pause」を選択します。 一時的にショートカットキーの割り当てを停止します。 Pause時のメニューの「Resume」を選択して復帰させることができます。
> - **拡張コマンドの編集**  
>    「Edit command」を選択します。 編集可能な拡張コマンド選択時のみ選択できます。
> - **ブックマークの編集**  
>    「Edit bookmark」を選択します。 ブックマークのときに選択できます。
> - **Descriptionの編集（メモ機能）**  
>    「Edit description」を選択します。 Remap/Disabled/Commentモード時に  
>    Descriptionが空欄のときに（Commentモード時は常時）選択できます。 メモ的な用途で利用します。  
> - **コンテキストメニューへの登録**  
>    「Create/Edit context menu」を選択します。 [コンテキストメニュー登録・編集](#ctxMenuOptions)ダイアログが開きます。
> - **バッチ実行の追加キーイベントの登録**  
>    「Add command」を選択します。 詳細は、[バッチ実行機能](#batch)を参照してください。
>

<a name="settings"></a>
##### Settings
> - **単独キーショートカットの有効化**  
>
>    チェックした場合、修飾キー（Ctrl、Alt、Winキー）なしで、ショートカットキーとして登録できます。  
>
>    次の点が、通常のショートカットキーと異なります。  
>        - ページスクリプトを利用する為、ページ読み込み中はキー入力を受け付けません。  
>        - テキスト入力欄では使用できません。 通常の文字入力になります。  
>        - Shiftキーとの併用時は、キーリピートが効きません。  
>        - 設定直後はすぐに使用できない場合があります。その際はページを読み込み直してください。   
>
> - **キーボードマクロ（バッチ実行モード）時の各キーストローク間の間隔**  
>
>    バッチ実行モード時、Remapモードのコマンド実行後にスリープされる時間を、ミリ秒単位で指定します。(0~1000msecの範囲)  
>
> - **キーボードタイプの選択**  
>
>    お使いのキーボードに合わせて、109日本語キーボードか、104英語キーボードのどちらかを選択します。  
>
> - **ショートカットキーヘルプ（support.google.com）の言語の選択**  
>
> - **アプリケーションアイコンの変更**  
>
>    ツールバーボタン、コンテキストメニュー、オプションページのFaviconで使用されるアイコンを変更することができます。  
>    アイコンファイルはPNG形式のみで、19x19ピクセルに自動的に変換されます。 32KBまでのファイルが指定できます。  
>  コンテキストメニューのアイコンは、拡張を再起動（リロード）後に変更されます。
>  
> - **Export/Import**  
>
>    現在の設定を保存したり、保存した設定データから取り込みます。  
>
>    [Exportタブ]  
>    - **Save Chrome sync**  
>    Chromeの同期機能を利用して、Googleのオンラインストレージに設定データを保存します。  
>    同期するChromeは、同じGoogleアカウントで使用する必要があります。  
>
>      但し、次の制限に該当する場合は利用できませんので、コピー&ペーストでExport/Importしてください。  
>        1. 設定データの全体のサイズが100KBを超える場合  
>        2. 一つのアイテム（1行のデータ内容）のサイズが4KBを超える場合  
>
>        *≪ご注意≫*  
>        複数のChrome/本拡張環境では、その内のどれか一つでも本拡張をアンインストールすると  
>        その時点で「Save Chrome sync」で保存した設定データは失われますので、ご注意ください。
>    - **Copy clipboard**  
>    設定データをクリップボードへ貼り付けます。  
>
>    [Importタブ]
>    - **Load Chrome sync**  
>    「Save Chrome sync」で保存した設定データをImport用のテキストエリアに読み込みます。  
>    - **Paste**  
>    クリップボードからImport用のテキストエリアに読み込みます。  
>    - **Load prev settings**  
>    Import実行後にボタンが有効になります。 Import実行後に、前回の設定に戻す場合に使用します。  
>    （Import実行前の設定をImport用のテキストエリアに読み込みます）  
>    オプションページを読み込み直すと無効になるのでご注意ください。  
>    - **Import**  
>    Importを実行します。  

<a name="command"></a>
##### 拡張コマンド一覧
>  
> - Tab  
>    - **Create new tab**  
>    アクティブなタブの右隣に、新しいタブを作成します。 新しいタブがアクティブになります。  
>    - **Create new tab in inactivate**  
>    アクティブなタブの右隣に、新しいタブを作成しますが、アクティブなタブは変更されません。  
>    - **Move current tab left/right**  
>    アクティブなタブを、左もしくは右へ一つ移動します。 最端位置から循環はしません。
>    - **Move current tab to first/last position**  
>    アクティブなタブを、左端(first)もしくは右端(last)へ移動します。
>    - **Close other tabs**  
>    アクティブなタブ以外の、現在のウィンドウ内のタブを、すべて閉じます。  
>    - **Close tabs to the left/right**  
>    アクティブなタブの左側もしくは右側のタブを、すべて閉じます。
>    - **Duplicate current tab**  
>    アクティブなタブを複製して、タブの右隣に新たに作成します。
>    - **Pin/Unpin current tab**  
>    アクティブなタブを、固定するか、もしくは固定されいている場合は固定を解除します。
>    - **Detach current tab**  
>    アクティブなタブを、ウィンドウから切り離して、新しいウィンドウに作成します。
>    - **Detach current tab　as panel**  
>    アクティブなタブを、ウィンドウから切り離して、新しいウィンドウに作成します。 タブ形式ではなく完全に独立したウィンドウになります。
>    - **Detach current tab　in an incognite window**  
>    アクティブなタブを、ウィンドウから切り離して、新しいシークレットウィンドウを作成します。 元のウィンドウに戻すことはできません。
>    - **Detach current tab**  
>    アクティブなタブを、ウィンドウから切り離して、新しいウィンドウに作成します。
>    - **Attach current tab to a next window**  
>    アクティブなタブを、現在開いている別のウィンドウに順次移動します。
>    - **Zooms current tab by fixed zoom factor**  
>    アクティブなタブを、固定倍率でズームします。 倍率は25%から500%まで1%単位で指定できます。
>    - **Zooms current tab by fixed zoom factor**  
>    アクティブなタブを、現在のズーム倍率に指定%を加算してズームします。 -100%から100%まで1%単位で指定できます。 結果が25%未満と500%超にはなりません。
> - Window  
>    - **Switch to the previous/next window**  
>    アクティブなウィンドウを順次切り替えます。
>    - **Close other windows**  
>    アクティブなウィンドウ以外のすべてのウィンドウを閉じます。
> - Browsing data  
>    - **Clear browser's cache**  
>    ブラウザキャッシュをクリアします。
>    - **Clear browser's cookies and site data**  
>    ブラウザのクッキーとサイトデータ（サーバ証明書等）をすべてクリアします。
>    - **Clear browsing history**  
>    ブラウザの履歴データをすべてクリアします。
>    - **Clear cookies for the current domain**  
>    アクティブなページのサイトと同じドメインのクッキーをすべてクリアします。
>    - **Clear tab history by duplicating the URL**  
>    アクティブなタブの履歴をクリアします。  
>    但し、単に同じURLのタブを新規作成して置き換えるだけなので、全体の閲覧履歴からは削除されません。  
> - Custom  
>    - **Paste fixed text**  
>    登録した定型文を、クリップボードを経由して貼り付けます。  
>    - **Open URL from external program**  
>    アクティブなタブのURLを引数に渡してOSのプログラムを実行します。  
>    IEやFirefoxなどのブラウザや指定したプログラムを起動できます。  
>    プログラムを指定する場合は、環境変数PATHからの相対パスか、または絶対パスを指定してください。  
>    - **Inject CSS**  
>    登録したCSS(Cascading Style Sheet)を、アクティブなタブのページへ適用します。  
>    - **Inject JavaScript**  
>    登録したJavaScript/CoffeeScriptコードを、アクティブなタブのページで実行します。  
>    なお、本来のページのDOMのwindowオブジェクトにはアクセスできません。

<a name="commandOptions"></a>
##### 拡張コマンドのオプション
> 拡張コマンド（Command mode）に追加オプションが必要な場合は、オプション入力ダイアログが開きます。
>
> - Paste text、Inject CSS、Inject JavaScriptのオプション
>    - **Title**  
>    オプションページのDescriptionに表示されます。 未入力の場合は、Contentに入力した1行目がセットされます。
>    - **Content**  
>    貼り付ける文字列(Paste text時)や、CSS(Inject CSS時)、JavaScriptコード(Inject JavaScript時)を入力します。  
> - Inject CSS、Inject JavaScriptのオプション
>    - **All frames**  
>    チェック時は、ページのすべてのフレームに、CSSやJavaScriptが適用されます。  
>    未チェック時はトップフレームにのみ適用されます。
> - Inject JavaScriptのオプション
>    - **CoffeeScript**  
>    チェック時に、CoffeeScriptでコードを記述できます。  
>    コンパイルオプションは"bare"で、コードはコンパイル済の状態で待機されます。  
>  
>        チェックすると「**Coffee**」と「**To JS**」というタブが出現します。  
>    「**To JS**」タブをクリックすると、事前にJavaScriptへの変換結果が確認できます。 変換結果の表示だけですので編集はできません。  
>    「**Coffee**」タブは、元のソースコードを表示します。（JavaScriptからの変換結果ではありません）  
>  
>        このチェックを外すと、現在表示されているコードがそのまま残ります。 JavaScriptへの変換結果を表示させたまま  
>    チェックを外すと、元のCoffeeScriptのコードは失われますので、ご注意ください。  
>    - **jQuery**  
>    チェック時に、jQueryを利用できます。  
>  
>        現在のjQueryのバージョンは、2.1.4です。  
>    - **Use utility object**  
>    チェック時に、JavaScriptからショートカットキーやクリップボードなどを操作できるObjectが利用できます。  
>    詳細は[Utility Object Reference](#utilobj)を参照してください。
>

<a name="bookmarkOptions"></a>
##### ブックマークのオプション
> ブックマークを選択すると、オプション入力ダイアログが開きます。
>
> - ブックマークを開くオプション  
>    - **Open in new tab** ....................... 新しいタブにブックマークを開きます。  
>    
>            Tab position: "Open in new tab"では、開くタブの位置を指定できます。  
>            "**Last**"- 右端、"**Right of current**"- アクティブタブの右側、"**Left of current**"- アクティブタブの左側、"**First**"- 左端  
>    - **Open in current tab** .................. 現在のタブにブックマークを開きます。  
>    - **Open in new window** ................ 新しいウィンドウにブックマークを開きます。  
>    - **Open in incognito window** ........ 新しいシークレットウィンドウにブックマークを開きます。  
>    - **Open as panel window** ............. 新しい独立したウィンドウにブックマークを開きます。  
>    - **Only to find the tab** .................. 開いているタブからブックマークを検索しますが、新しいブックマークは開きません。  
>    - **Open an inactive tab/window**  
>        開くタブまたはウィンドウを、アクティブにしない場合にチェックします。
> - ブックマークを検索するオプション
>    - **Activate the tab if already open**  
>        チェック時、開いているタブからブックマークを検索して、見つかった場合はそのタブをアクティブにします。  
>        複数見つかった場合は、順次アクティブになります。
>    - **The title or URL to find (Partial match)**  
>        検索するブックマークの**URL**または**タブのタイトル**を入力します。 中間マッチで検索されます。

<a name="ctxMenuOptions"></a>
#####  コンテキストメニューへの登録・編集
> 各行の右端に表示されるアイコンボタン[<i class="icon-caret-down"></i>]クリック時のメニューから  
> 「Create/Edit context menu」を選択すると、コンテキストメニュー登録・編集のダイアログが開きます。
> <pre>
> コンテキストメニューを登録すると、コンテキストメニュー（ページを右クリックしたときに表示されるメニュー）から  
> ショートカットキーに割り当てた機能を呼び出すことができます。
>
> また、拡張コマンドのInject JavaScriptで利用できる、UtilityObjectのctxDataプロパティの値に対象コンテキストの情報がセットされ  
> JavaScriptコードから参照することができます。
> </pre>
>
> 入力項目
>
> - **Menu Title**  
>    コンテキストメニューに表示される文字列を指定します。  
>
>    テキスト選択(Selection)のコンテキストメニューの場合、文字列中の「%s」の箇所が、選択中のテキストに置き換わります。  
>    アルファベットの頭文字か、&+アルファベットが、キーショートカットになります。 '&'を表示したい場合は、'&&'と2つ続けて記述します。
>
> - **Target Context**  
>    コンテキストメニューのメニュー項目は、右クリックする対象（コンテキスト）により異なります。  
>    どの対象のコンテキストメニューで表示させるかを選択します。
>
>    - **Page**  
>    ページ全般で、リンクや画像、テキスト選択など何もない場所でのコンテキストメニュー  
>    ページのトップフレームのURLが返されます。
>    - **Selection**  
>    テキストを選択した状態（ハイライト）でのコンテキストメニュー  
>    選択テキストが返されます。
>    - **Editable**  
>    テキストボックスやテキストエリアなどのテキスト入力要素のコンテキストメニュー  
>    入力テキストを選択ハイライトしている場合は選択テキスト、それ以外はページのURLが返されます。
>    - **Link**  
>    リンクを右クリックしたときのコンテキストメニュー  
>    リンクのURLが返されます。
>    - **Image**  
>    画像を右クリックしたときのコンテキストメニュー  
>    画像のURLが返されます。
>    - **Toolbar button**  
>    ツールバーボタンのコンテキストメニュー  
>    - **All**  
>    すべてのコンテキストメニューに表示されます。 対象により上記のいずれかが返されます。
>
> - **Parent folder**  
>    コンテキストメニュー項目を配置するフォルダーを作成または選択します。  
>    - *None(Root)*  
>    コンテキストメニュー直下にメニュー項目を作成します。  
>    但し、対象コンテキストに、メニュー項目を２つ以上作成した場合は、自動的にフォルダ「Shortcutware」配下にメニュー項目が作成されます。  
>    これはChrome拡張のコンテキストメニューの仕様です。  
>    このとき、「S」が親メニューのキーショートカットになります。
>    - *Create a new folder...*  
>    新しいフォルダを作成し、その配下にコンテキストメニュー項目を作成します。  

<a name="ctxMenuManager"></a>
#####  コンテキストメニューの管理
> オプションページトップのボタン「**Context menu mgr**」をクリックすると表示されます。  
> 登録されているコンテキストメニューの構成を編集できます。
>
> なお、[コンテキストメニューへの登録・編集](#ctxMenuOptions)と一部機能が重複しますので、好みで使い分けてください。（機能的には本画面ですべて賄えます）  
> 重複する機能やコンテキストメニュー機能の説明については、[コンテキストメニューへの登録・編集](#ctxMenuOptions)を参照してください。  
>
> - ボタン説明
>
>    - **Add Menu**  
>    コンテキストメニュー登録の候補を追加します。 TargetContextかフォルダ選択時にクリックできます。  
>    
>        オプションページトップにフォーカスが移るので、登録したいショートカットキー機能を選択して、Addボタンをクリックします。<br />
>        選択は、Ctrlキー+マウスクリックか、マウスで範囲選択すると複数選択できます。
>    - **Add Folder**  
>    サブメニューの親メニュー（フォルダ）を追加します。 TargetContext選択時にクリックできます。  
>    サブメニューは1階層のみ登録可能です。
>    - **Rename**  
>    フォルダ名またはコンテキストメニュータイトルを編集します。 フォルダ、コンテキストメニュータイトル選択時にクリックできます。  
>    - **Remove**  
>    フォルダまたはコンテキストメニュー登録を削除します。 フォルダ、コンテキストメニュータイトル選択時にクリックできます。  
>
>        Doneボタンをクリックするまで実際のコンテキストメニューからは削除されません。  
>    - **Done**  
>    編集内容がコンテキストメニューに反映されます。  
>    コンテキストメニューが存在しない空になったフォルダは削除されます。  
>
> - コンテキストメニュー構成の変更  
>
>     コンテキストメニュータイトルまたはフォルダは、マウスのドラッグ操作で、並び順やTargetContextを変更できます。   

<a name="batch"></a>
#####  バッチ実行機能
> 一つのショートカットキーで、複数のショートカットキー機能や拡張コマンド、ブックマーク機能を呼び出すことができます。  
>
> 各行の右端に表示されるメニューボタン[<i class="icon-caret-down"></i>]から、「**Add command**」を選択して  
> 呼び出す機能をそのショートカットキーに追加していきます。
>
> 一つ以上追加することで、そのショートカットキーは自動的にバッチ実行モードになります。
>
> - 機能を追加されたショートカットキーの機能は、親機能になり、「**Comment**」モードが選択できるようになります。  
>   親機能の行を「Comment」モードにすることで、バッチ実行の見出しにするができます。  
>
>   追加した機能では、「**Sleep**」と「**Comment**」モードが選択できるようになります。  
> - 追加した各機能は、追加した順に、上から順次呼び出されます。  
> - 基本的に、一つの機能の呼び出しが終わってから、次の機能が呼び出されますが  
>    呼び出しが終わっても、その呼び出された機能自体は完了していない場合があります。  
>
>    このような場合で、前の機能が完了してから次の機能を実行したい場合は  
>    「**Sleep**」モードの行を追加して次の機能呼び出しのタイミングを調整してください。
> - 「**Sleep**」モードの初期値は100ミリ秒(1/10秒)です。
>
>    設定できる範囲は、0から60000ミリ秒(1分)までです。 表示されている値の横のアイコン<i class="icon-pencil"></i>をクリックすると編集できます。  
> - 追加した機能は、上下移動のアイコンボタンをクリックすることで、順番を変更することができます。  

<a name="notes"></a>
##### 備考・注意事項
> - オプションページの設定の保存は自動的に行われます。 特に保存ボタン等はありません。  
>    （タブまたはウィンドウの切り替え時に保存が実行され、設定はすぐに反映されます）
> - オプションページは各行をドラッグして並び順を変更できます。  
>    なお、行が多く、スクロールバーが表示されている状態のとき、ドラッグ中にスクロールされないときがありますが  
>    そのときはタイトルや周りの余白をクリックしてから再度試みてください。  
> - 登録できるアイテム数は、バッチの子アイテムも含めて、最大100個までです。
> - ブックマーク、定型文貼り付け、CSS挿入、JavaScript実行機能ではキーリピートは効きません。  
>
>    定型文貼り付けでは、クリップボードにテキストが残っているので  
>    キーリピートさせたい場合は、Ctrl+V(または相当のショートカットキー)に切り替えてください。
> - 他のChrome拡張と同じく、Chrome設定関連のページやローカルファイルページでは、本拡張は無効になります。（単純なキーリマップは有効です）
> - マウスホイールのタブ切り替えで高分解能マウスは未検証です。
>

<a name="utilobj"></a>
##### Utility Object Reference

> **Methods**
>
> ###### `scd.send(string keycode [, optional integer sleepMillisecond])`  
> >  
> > ショートカットキーを呼び出します。  
> > リマップや拡張コマンド、ブックマークを割り当て済みのショートカットキーはそれらが呼び出されます。  
> > 自己参照、循環参照がある場合は無限ループになってしまう為、注意してください。
> >
> > - _keycode(string)_  
> >
> >    書式: [_modifierkeys_]_keyIdentifier_    
> >
> >    _modifierkeys_は**C**trl,**A**lt,**S**hift,**W**inキーの頭文字の組み合わせを指定します。  
> >    単独のファンクションキーのときは角括弧を省略できます。
> >
> >    _keyIdentifier_はキートップに刻印されている文字をそのまま指定します。  
> >    この際、Shiftキーが含まれるときでも、大文字や上段シフトの文字を指定する必要はありません。（どちらでも構いません）  
> >    特殊キーについては、ショートカットキー登録時の値を参照してください。 大文字小文字を区別します。  
> >
> >    ショートカットキー以外の単独キーは無視されます。  
> >
> > - _sleepMillisecond(integer default 100)_  
> >
> >    メソッド実行後の、次のscdオブジェクトメソッドが実行されるまでの間隔を、ミリ秒単位で指定します。  
> >    値の範囲は、0-60000(60秒)までで、値を指定しない場合の規定値は100ミリ秒です。  
> >    なお、通常のJavaScriptコマンドには影響しません。  
> >
> > Code Exsample  
> >
> > 次のコードは、タブを左隣りに作成します。
> > <pre>
> > scd.send('[ca]n'); /* Ctrl+Alt+n Create new tab を割り当てたショートカットキーを呼び出し */
> > scd.send('[ca]z'); /* Ctrl+Alt+z Move current tab left を割り当てたショートカットキーを呼び出し */
> > </pre>

> ###### `scd.keydown(string keycode [, optional integer sleepMillisecond])`  
> >  
> > 指定したキーを押下します。 単独キーも指定できます。  
> > ショートカットキーを指定した場合は、リマップ等割り当て済みのショートカットキーでもそれらは呼び出されず、単にキー押下が実行されます。
> >
> >    引数の書式は_send_メソッドと同じです。
> >
> > Code Exsample  
> >
> > 次のコードは、ウィンドウを閉じるときに確認してから閉じます。  
> > Ctrl+Shift+W（Chrome標準のウィンドウを閉じるショートカットキー）に割り当てた場合を想定しています。
> > <pre>
> > if (confirm('ウィンドウを閉じますか？')) {
> >   scd.keydown('[cs]w'); /* sendメソッドでは自己参照になってしまう為、keydownメソッドを使用 */
> > }
> > </pre>
> >
> > 次のコードは、ページのソースを開いてコピーするか保存するかして、開いたソースのページを閉じます。
> > <pre>
> > scd.keydown('[c]u', 1000); /* Ctrl+u 現在のページのソースを開きます。実際のページが表示されるまでの猶予を1秒見ています。 */
> > scd.keydown('[c]a');       /* Ctrl+a */
> > scd.keydown('[c]c');       /* コピーする場合。Ctrl+c ハイライト表示されたコンテンツをクリップボードにコピーします。 */
> > scd.keydown('[c]s', 1000); /* 保存する場合。Ctrl+s 現在のページを保存します。 */
> > scd.keydown('Enter');      /* Enterキー */
> > scd.keydown('[c]w');       /* Ctrl+w 現在のタブまたはポップアップを閉じます。 */
> > </pre>
> >
> > 次のコードは、選択したテキストをページ内検索します。  
> > また、何も選択しないで実行した場合は、クリップボードにあるテキストが検索されます。
> > <pre>
> > scd.keydown('[c]c'); /* Ctrl+c ハイライト表示されたコンテンツをクリップボードにコピーします。 */
> > scd.keydown('[c]f'); /* Ctrl+f 検索バーを開きます。 */
> > scd.keydown('[c]v'); /* Ctrl+v クリップボードからコンテンツを貼り付けます。 */
> > </pre>
> >
> > 次のコードは、リンクになっていないURLを選択した場合にそのURLを開きます。（通常のテキストはGoogleでの検索）  
> > また、何も選択しないで実行した場合は、クリップボードにあるテキストが検索されます。
> > <pre>
> > scd.keydown('[c]c');
> > scd.send('[ca]n');    /* Ctrl+Alt+n Create a new tab を割り当てたショートカットキーを呼び出し */
> > scd.keydown('[c]v');
> > scd.keydown('Enter'); /* Enterキー */
> > </pre>
<!--
> >
> > 次のコードは、ブックマークバーを開き、更にその他のブックマークフォルダを開きます。
> > <pre>
> > scd.keydown('[cs]b');     /* Ctrl+Shift+b ブックマーク バーの表示/非表示を切り替えます。 */
> > scd.keydown('F6', 200);   /* F6 キーボードからアクセス可能な次のペインにフォーカスが移動します。 */
> > scd.keydown('F6', 200);   /* F6 キーボードからアクセス可能な次のペインにフォーカスが移動します。 */
> > scd.keydown('Left', 200); /* ←（左カーソルキー） */
> > scd.keydown('Down', 200); /* ↓（下カーソルキー） */
> > </pre>
-->

> ###### `scd.sleep(integer sleepMillisecond)`  
> >  
> > 指定したミリ秒間スリープして、次のscdオブジェクトメソッドの実行開始を遅らせます。  
> > なお、通常のJavaScriptコマンドには影響しません。

> ###### `scd.openUrl(url string [, optional inactivate boolean, optional findTitleOrUrl string, optional position string])`  
> >  
> > 指定したURLのタブを新たに開きます。  
> > オプションで、バックグラウンドで開いたり、最初にタブを検索して無ければ新たなタブで開くようにすることができます。  
> >
> > なお、バッチ実行モード時は、このメソッド実行後は、バックグラウンドで開いたり検索された場合でも  
> > 次以降のコマンドは、そのタブがアクティブタブとして実行されます。  
> >
> > - _url(string)_  
> >
> >    URLは、スキーム名(HTTP(S))から始まる完全なURLを指定します。  
> >    検索だけしたい場合は、nullを指定します。  
> >
> > - _inactivate(boolean)_  
> >
> >    タブまたはウィンドウをアクティブにしない場合に、trueを指定します。  
> >    
> > - _findTitleOrUrl(string)_  
> >
> >    検索するタブのタイトルまたはURLを指定します。 部分一致で検索されます。  
> >    
> > - _position(string)_  
> >
> >    新しくタブを開く場合に、タブの位置の文字列を指定します。 規定値は"last"です。  
> >    
> >    "left"- アクティブタブの左側、"right"- アクティブタブの右側、"first"- 左端、"last"- 右端  
> >    "newwin"- 新しいウィンドウ、"incognito"- 新しいシークレットウィンドウ  
> >    
> > [Code Exsample](#codeExsample1)

> ###### `scd.showNotify(title string, message string [, optional icon string, optional newPopup boolean])`  
> >  
> > タイトル付きメッセージを、画面右下に表示されるデスクトップ通知ウィンドウに表示します。  
> > オプションで、既定のアイコンを表示したり、ウィンドウの表示方法を指定できます。  
> >
> > - _title, message(string)_  
> >
> >    通知ウィンドウのタイトル（太字表示）と本文を指定します。  
> >    表示できる文字数は、おおよその目安で、タイトルが半角30文字程度×3行、本文が半角30文字程度×7行までです。
> >
> > - _icon(string)_  
> >
> >    次の既定のアイコンの名前を指定します。  
> >    アイコンを表示させない場合は、既定外の値またはnullを指定します。
> >    
> >    <img src="../images/info.png">[info]<img src="../images/warn.png">[warn]<img src="../images/err.png">[err]<img src="../images/chk.png">[chk]<img src="../images/close.png">[close]<img src="../images/help.png">[help]<img src="../images/fav.png">[fav]  
> >    <img src="../images/infostar.png">[star]<img src="../images/clip.png">[clip]<img src="../images/comment.png">[comment]<img src="../images/comments.png">[comments]<img src="../images/user.png">[user]<img src="../images/users.png">[users]
> >
> > - _newPopup(boolean)_  
> >
> >    既定では、一つのウィンドウだけを更新しますが、常に新たなウィンドウを開く場合に、trueを指定します。

> ###### `scd.setClipbd(string text)`  
> >  
> > 文字列をクリップボードに貼付けます。
> >
> > Code Exsample  
> >
> > 次のコードは、URLのリンクタグをクリップボードに貼り付けます。
> > <pre>
> > var url = document.location.href;
> > var elTitle = document.querySelector('title'), title;
> > if (elTitle) {
> >   title = elTitle.textContent;
> > } else {
> >   title = url;
> > }
> > scd.setClipbd('&lt;a href="' + url + '"&gt;' + title + '&lt;/a&gt;');
> > </pre>

> ###### `scd.send(...).done(function callback)`  
> ###### `scd.keydown(...).done(function callback)`
> ###### `scd.sleep(...).done(function callback)`
> ###### `scd.setClipbd(...).done(function callback)`
> >  
> > 各scdオブジェクトメソッドの呼び出しを終了してから、登録したファンクションを実行します。  
> > スリープを指定していた場合は、スリープ時間経過後に実行されます。
> >
> > scdオブジェクトメソッド間は自動的に同期されるため、このメソッドは必要ありません。
> >
> > Code Exsample  
> >
> > <pre>
> > scd.sleep(5000).done(function() { alert('5秒経過'); });
> > </pre>

> ###### `scd.getClipbd().done(function callback(string text))`  
> >  
> > クリップボードにあるテキストを取得します。
> >
> > 取得するテキストは、_done_メソッドに登録したコールバックファンクションに渡される引数から取得する必要があります。
> >
> > Code Exsample  
> >
> > <pre>
> > scd.getClipbd().done(function(text) { alert(text); });
> > </pre>

> ###### `scd.setData(string name, object value)`  
> >  
> > コマンド間の共有データを保存します。 保存したデータは本拡張がアンロードされるまで有効です。  
> >

> ###### `scd.getData(string name).done(function callback(object value))`  
> >  
> > 保存した共有データを取得します。  
> >

> ###### `scd.getSelection()`  
> >  
> > ページ上の選択してハイライトされている文字列を返します。  
> > window.getSelectionとの違いは、TEXTAREAとINPUT(TEXT)エレメントの選択文字列も返します。  
> > 何も選択されていないときは空文字を返します。
> >
> > 次のコードは、選択したテキストをページ内検索します。  
> > 何も選択しないで実行した場合は、検索ボックスは空か前回検索時の値になります。  
> > <pre>
> > scd.setClipbd(scd.getSelection()); /* 選択中の文字をクリップボードにコピーします。 */
> > scd.keydown('[c]f'); /* Ctrl+f 検索バーを開きます。 */
> > scd.keydown('[c]v'); /* Ctrl+v クリップボードからコンテンツを貼り付けます。 */
> > </pre>
> >

> ###### `scd.cancel()`  
> >  
> > バッチ実行モードのときに、後続のコマンドの実行をすべてキャンセルします。
> >

> ###### `scd.execShell(string filePath [, optional string parameter])`  
> >  
> > 指定したOSのプログラムを実行します。
> >
> > - _filePath(string)_  
> >
> >    実行するプログラムまたはファイルのOSのパスを指定します。  
> >    環境変数PATHからの相対パスか、またはドライブから始まる絶対パスを指定します。  
> >    なお、パスの区切り文字は¥を2つ続けて記述してください。  
> >
> > - _parameter(string)_  
> >
> >    プログラムに渡す引数を指定します。  
> >
> > Code Exsample  
> >
> > 次のコードは、Linkに登録したコンテキストメニューからの呼び出しで、InternetExplorerを起動します。
> > <pre>
> > scd.execShell('C:¥¥Program Files (x86)¥¥Internet Explorer¥¥iexplore.exe', scd.ctxData);
> > </pre>

> **Properties**  
>  
> ###### `scd.ctxData(string)`  
> >  
> > コンテキストメニューからスクリプトが呼ばれた場合に、対象コンテキストの情報がセットされます。
> >
> > このプロパティの値は、次のコンテキストメニュー呼び出しがあるまで変更されず、
> > 他のスクリプトからも同じ値が参照できます。
> >

<a name="codeExsample1"></a>
> Code Exsample  
> >  
> > 次のコードは、ブラウザ上のテキストエディタの選択テキストにラインコメント//を追加します。(CoffeeScript - Toggle line comments "//")  
> > <pre>
> > setNewText = (newTxt) ->
> >     scd.setClipbd newTxt
> >     scd.keydown "[c]v"
> >
> > re = /(^\s+\/|^\/)\/+?/
> >
> > if (txt = scd.getSelection()) is ""
> >     scd.keydown "Home"
> >     scd.keydown("[s]End").done ->
> >         if re.test txt = scd.getSelection()
> >             setNewText txt.replace(re, "")
> >         else
> >             scd.keydown "Home"
> >             setNewText "//"
> > else
> >     newTxts = []
> >     txt.split("\n").forEach (line) ->
> >         if re.test line
> >             newTxts.push line.replace(re, "")
> >         else if line is ""
> >             newTxts.push line
> >         else
> >             newTxts.push "//" + line
> >     setNewText newTxts.join("\n")
> > </pre>
> > <br>
> > 次のコードは、GoogleやAmazon等で検索結果が複数ページのときに次のページへ移動します。(CoffeeScript - Pager "Next")  
> > <pre>
> > expr = []
> > expr.push [/www\.google/, "id('pnnext')"]
> > expr.push [/www\.amazon/, "id('pagnNextLink')"]
> > expr.push [/.*/, "//a[translate(text(), 'のページへ> ', '')='次']"]
> >
> > url = location.href
> > for i in [0...expr.length]
> > 	if expr[i][0].test url
> > 		xpath = expr[i][1]
> > 		break
> > if xpath
> > 	result = document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null)
> > 	if el = result.singleNodeValue
> >         #location.href = el.getAttribute("href") #直接リンクのURLへ移動する場合
> > 		evt = document.createEvent "MouseEvents"
> > 		evt.initEvent "click", true, true
> > 		el.dispatchEvent evt
> > </pre>
> > <br>
> > バッチ実行モードでのコードサンプルです。  
> > 選択中の英文テキストを、Google翻訳に渡して翻訳結果をデスクトップ通知ウィンドウに表示します。  
> > コンテキストメニューのSelectionに登録する場合を想定しています。  
> >
> > Inject JavaScript① Google翻訳ページに英文テキストを渡してバックグラウンドで開きます。(CoffeeScript)  
> > <pre>
> > if selection = scd.getSelection()
> >   scd.openUrl 'http://translate.google.co.jp/#en/ja/' + encodeURIComponent(selection), true
> > else
> >   scd.cancel()
> > </pre>
> > Inject JavaScript② 翻訳結果を通知ウィンドウに表示してGoogle翻訳ページは閉じます。（CoffeeScript, jQuery）
> > <pre>
> > timer = null
> > $('#result_box').on 'DOMSubtreeModified', (event) ->
> >   if timer
> >     clearTimeout timer
> >   timer = setTimeout((->
> >     scd.showNotify $('#source').val(), event.currentTarget.textContent, 'info'
> >     window.close()
> >   ), 100)
> > </pre>
