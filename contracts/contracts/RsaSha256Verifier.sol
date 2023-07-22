//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.5
//      fixed linter warnings
//      added requiere error messages
//
pragma solidity >=0.5.0;

library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }

    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return
            G2Point(
                [
                    11559732032986387107991004021392285783925812861821192530917403151452391805634,
                    10857046999023057135944570762232829481370756359578518086990519993285655852781
                ],
                [
                    4082367875863433681332203403145435568316851327593401208105741076214120093531,
                    8495653923123431417604973247489272438418190587263600148770280649306958101930
                ]
            );

        /*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }

    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }

    /// @return r the sum of two points of G1
    function addition(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "pairing-add-failed");
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(
        G1Point memory p,
        uint s
    ) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "pairing-mul-failed");
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(
        G1Point[] memory p1,
        G2Point[] memory p2
    ) internal view returns (bool) {
        require(p1.length == p2.length, "pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(
                sub(gas(), 2000),
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }

    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }

    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            3729759902613158737584667451763372650786205291355292152976183853465281741568,
            12141818571021242890877607823917100116000365301195201631232395613768357031550
        );
        vk.beta2 = Pairing.G2Point(
            [
                13136239927450321420640914360716128650905558296901801053963909067006351325961,
                15158152606360031483103218567077180987695153184296747211468761930524229437793
            ],
            [
                5915853304591152121704470374932450228803136872189869158933925105543608134284,
                15730504375151781974211308982636760944102253372011186196057356583318925951174
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                12797338069690577808446516054250140565574683028551313720352971263472998915296,
                20208022052319197615373299594326862684574957199303386410392870171291317902333
            ],
            [
                9510633293756122824931415204113148296568119183289757074341033791433603022461,
                13848313324479398811493408106201633294081396281714935002300111704965563936458
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                11266660693726079180142591384137499556300910320758103405829939699434501821711,
                159594287871630790884118904172491478917812927426735012058598943236280092311
            ],
            [
                707654447428566954854247517328264835096719281326792298268083684720121778002,
                8298750859219747276182424982921391214869766140065874201121654684399272269872
            ]
        );
        vk.IC = new Pairing.G1Point[](101);
        vk.IC[0] = Pairing.G1Point(
            12559857560137645122326787789388304194293993587871847134890494756734887730889,
            10540836150835001110742597252815405926154507219744289543571939471050967928634
        );
        vk.IC[1] = Pairing.G1Point(
            12658759479213995965001162601252332272297201132548324564145207426693527565148,
            15926932667955163852247956764952692134227328819400283042400340320607443890254
        );
        vk.IC[2] = Pairing.G1Point(
            9233280406365537882472347091592984624804190391541341875802125235730278068104,
            15752275523345009693961145001656538975922631355936481038733513488525164988505
        );
        vk.IC[3] = Pairing.G1Point(
            21808090471321077445113540295542855177220849182527518892630816833213211110034,
            20291869163317933772360342832189914678441059039982932543926622212723342658188
        );
        vk.IC[4] = Pairing.G1Point(
            1681702107650924242939590994184892198098972482270962181163847232267596328979,
            8557342808420608015163852437969816624820953791079871399330708760568396310181
        );
        vk.IC[5] = Pairing.G1Point(
            15827623790091259354160909641747466114900068219744403763028569679077212891836,
            16047900434997519505683285569042075748171171960928956378651963933769052004008
        );
        vk.IC[6] = Pairing.G1Point(
            3871649391107353865241916568957195781306573935564276180600325739625953633118,
            12287152472530723322413958924122061475582275721639684996612866595376739186461
        );
        vk.IC[7] = Pairing.G1Point(
            8377106463810514100685825845356383395677386067510355919238576094169118852098,
            16519583242327369166921875830238594086615876675834667310581495770465471479636
        );
        vk.IC[8] = Pairing.G1Point(
            17256315274839085951460383359477120338705730100085167250100861170794470772637,
            3419545622500035714248118081256268218279679027326858006315366263619362796192
        );
        vk.IC[9] = Pairing.G1Point(
            2593537711230008662417588173639335118988856157197429149412196836978036476028,
            8538157445492015981727851706347554419011993838886631881562298143422560139294
        );
        vk.IC[10] = Pairing.G1Point(
            14477989853705726354071915375794761972851384384757175470793846199714539784558,
            14079929937676588910688882040816627480763684460772620450631541411202100526288
        );
        vk.IC[11] = Pairing.G1Point(
            4908367875710967666263674799257760084919139359752249693676456246609727636200,
            5893464791638555403716448258880869242115708620115670515122632157362553235348
        );
        vk.IC[12] = Pairing.G1Point(
            13892778185221937690942368826832812063265428592570499824044925689738310219507,
            11461753429365510455202142741940060316305242731650721498478106876233632658526
        );
        vk.IC[13] = Pairing.G1Point(
            10682134970087788592471914065872857208315069548941037969986310598376249004732,
            14820627352105689049749766052640486401273173176923086067015878857939901878602
        );
        vk.IC[14] = Pairing.G1Point(
            2119772198982403375642033192857705104561760415182630621394416503820521967779,
            16584064631567314702849101035907475762114845357796927805769715977242748798669
        );
        vk.IC[15] = Pairing.G1Point(
            468001957379087412141235349803020719399535626031098531020103076502018103392,
            9731847692529878033421967337165792006328738092348010242836175102062482640062
        );
        vk.IC[16] = Pairing.G1Point(
            5976854251484892985782710636217625469859800520275598568134507262077496024875,
            20318938400718660685673332319353492933668237552172622506369401471105652570305
        );
        vk.IC[17] = Pairing.G1Point(
            2270094903612716086771825446969605944149896602655214340134275658651750853226,
            18941736206768559100014313431303112513260697052358590666556859967328261755214
        );
        vk.IC[18] = Pairing.G1Point(
            12403449502829396741529042798889605750120840857422439904793273456469011902972,
            9789585080677337609512672344440040203261250373286666180411916849321683055718
        );
        vk.IC[19] = Pairing.G1Point(
            5555650403718658868411141337590093679981609731619594603339902419923925020353,
            20995211797979700202498069667261619609850065140932834745505873830679692372592
        );
        vk.IC[20] = Pairing.G1Point(
            17021767833623025872249331730705710377933197645216218331094616026361430597609,
            21329825675699865933034689118999077871032105338144922154354087349843672509618
        );
        vk.IC[21] = Pairing.G1Point(
            13558385097045770902864137581806672992871490316835972998797790572516541506114,
            5871014328309830011352420589638285888179320152051847574807457074880403066141
        );
        vk.IC[22] = Pairing.G1Point(
            16424514168975252965671923544446270352171954723319017563341096325380655713361,
            10859685700990652881520664344470801502388465114367176442614087797358727366623
        );
        vk.IC[23] = Pairing.G1Point(
            5959902219511275843292344410423896996238815584716983284173265190637438847590,
            9866932316233122640717186062840841537434267117425416230387060170619909871391
        );
        vk.IC[24] = Pairing.G1Point(
            1603092778495767604469588986389709237236493500171281056848466995620519963878,
            10011230165505730565598760395108917820136844145671763984779303282793398036278
        );
        vk.IC[25] = Pairing.G1Point(
            19445203104268502694085960460918715911378008052266742102134951305696244481932,
            18844398769848149633147971476338348359312024666594833610275881857280050865385
        );
        vk.IC[26] = Pairing.G1Point(
            1911019365654561636810416312706988526422489945391846257575313065585724936388,
            4328460448192713619136628242809821670510740784986141355766087498495263044440
        );
        vk.IC[27] = Pairing.G1Point(
            7308114787300765260833382420461011775799539650740129702114708263446235846501,
            14889543655495891179002456830623939070826438837228365469197541904090781285175
        );
        vk.IC[28] = Pairing.G1Point(
            21639806011468686866574898817328015655531783301049300937998792525082477069075,
            275600735308784979838399243296684752583895839757668037687219635002720004115
        );
        vk.IC[29] = Pairing.G1Point(
            20376116057487924525276918026031289707778502172020349017437375506132045737517,
            19626268801008909613613890378709127489942986964980481543791425928839613527266
        );
        vk.IC[30] = Pairing.G1Point(
            13592009692949030004574896973195032080900164083505630280697715821763123369164,
            5790907420455211091536725334579794280394459354328483860650869413952658359343
        );
        vk.IC[31] = Pairing.G1Point(
            1628493535906882612797992608275773632370164503966508208193089026140677105123,
            13482183750711332376169797918240691246931490543951556091861566531310767503698
        );
        vk.IC[32] = Pairing.G1Point(
            18259742122100526632130511216014839454173201065604812935967390249533409095042,
            5280386665815101163919341992262974722171658412973558382680082465740734248990
        );
        vk.IC[33] = Pairing.G1Point(
            6443894117860652890119529010273675480419927094850244013306680814669496732337,
            11867190429733051312323586554625563629455203502247421507932910643975163792166
        );
        vk.IC[34] = Pairing.G1Point(
            14881820047534513998342158226070155246972777382419986458007544494090526092189,
            21439288798623183508506732895142794473218295271986600930799453199416275082474
        );
        vk.IC[35] = Pairing.G1Point(
            6637337966321834484004997695297890794429484223988098988196214552643297179527,
            4140984639167223308355869685451740772856320877650177711101971172889089529744
        );
        vk.IC[36] = Pairing.G1Point(
            14320962606625310252457563082348347637781609365245721306020447239610881132573,
            4355428558647072618942274565841030436504076288251109685532050786296048117047
        );
        vk.IC[37] = Pairing.G1Point(
            15366769631851752354143870656040697905161609081800490314563812863474624292450,
            4662453582922910336824127766333371939884681188295201896157157328891342699708
        );
        vk.IC[38] = Pairing.G1Point(
            17721891774056849019223190636020057314863547956224207111926175144984438341674,
            6175192763929100699638150965668647330732349761476747365579610301167554102544
        );
        vk.IC[39] = Pairing.G1Point(
            12108556731527282476656416278846047917916614928311966513552277657271130491935,
            12482533820340806038841922711984697523097157464283617092458735682492807434689
        );
        vk.IC[40] = Pairing.G1Point(
            18886092892941247857051157848944267364349578158082972696311532364504024371981,
            19812052634637182218047217965035478162772751733537338114674670792578859230909
        );
        vk.IC[41] = Pairing.G1Point(
            3723725291911652431008916713263794352220829189736925775917633975310219729453,
            20463189283374303708989740698253633548346610467325597828389662987611493042372
        );
        vk.IC[42] = Pairing.G1Point(
            13275998810754415624632619359378959965142615339099289942518847164921612336349,
            955114550629205825342327224716527590631889353685073541925190495009566832234
        );
        vk.IC[43] = Pairing.G1Point(
            8127814461915026185786513617437682859742298705009503581737619364170030447116,
            21815819203989494603085212132332810378548897564403488275705674583099354027961
        );
        vk.IC[44] = Pairing.G1Point(
            7487475274169718977265746701319573156726267921915085570273189839189674445754,
            5201014436553051239372574945567405202353368683371168424706141117865315558571
        );
        vk.IC[45] = Pairing.G1Point(
            5924521840605251028718217723025645499739101773307750914599024520374451885719,
            19428818752090942780423549177176836985207944484638996290285447987180802804701
        );
        vk.IC[46] = Pairing.G1Point(
            19236678798478568184257218598238736474256699019074034203560137661980839276026,
            3139750861809295800845306937286058569462063739980203065998438406055759875643
        );
        vk.IC[47] = Pairing.G1Point(
            2418570367199724236587628998150956846382594750061617948621490926643435241166,
            3127319167851697820463127295938241108917118724647062263004343701785256270853
        );
        vk.IC[48] = Pairing.G1Point(
            10909492437751379338188199652628936747937724199500813788942572863509477583010,
            4833308865394489067757406533756587852982195128697164261612054340912519530021
        );
        vk.IC[49] = Pairing.G1Point(
            4625826633705154901376833829227093358179171397356950311175901450119871326092,
            117381311528237548316177716726652775298685292414608571831406223150392712462
        );
        vk.IC[50] = Pairing.G1Point(
            11341370844202293686695076488062249710145992973415434244350913310878091873666,
            2679592152865543054483479749342604715904461512197943637959128980231382841200
        );
        vk.IC[51] = Pairing.G1Point(
            17609783486458107655758975986039577766535204121270405693756192976423973524335,
            10170503815852453711175195241826129330807849924579505856085876739462624724479
        );
        vk.IC[52] = Pairing.G1Point(
            13618393604972347384993673349559696624891668790999087327294997970318668323093,
            8597452137927565226995995089969355848121140362662198798261258182931073349319
        );
        vk.IC[53] = Pairing.G1Point(
            1369052766836407521905711845908024536009180793492574158258994707081494629126,
            5291609899883605798795618997799719454716671977081560623022622321418203167294
        );
        vk.IC[54] = Pairing.G1Point(
            17476288512285277772225244608787933636200743838838180917949789071831401016014,
            6832015928227769155216978404915572773960282476794917046601166303693051471745
        );
        vk.IC[55] = Pairing.G1Point(
            21058356558830289350565492498601960315583764018539526572244572347296204478038,
            17800635316802079857985933967175756927585005558861771454945139618335207360711
        );
        vk.IC[56] = Pairing.G1Point(
            18887475735208246902422084857021154587515200986100034744871684624373946415913,
            3650665502072512890897429420208767872268785767071942030996307571559141487708
        );
        vk.IC[57] = Pairing.G1Point(
            15304064583441452978954055182325447214811873398750472936801929759372769521146,
            17092533988014354887696753785030909830699886830432410934834150980380514405170
        );
        vk.IC[58] = Pairing.G1Point(
            16354407224230673074519339586655638610503081836647667623814986520923128018304,
            14634681859267375125892101837735696597319439744437447535401719559097971351455
        );
        vk.IC[59] = Pairing.G1Point(
            12585902321015589710750473831345538579594885660392175544266943980185107256475,
            16846205462256028916608587497640916256009966086610491220765532912482788390078
        );
        vk.IC[60] = Pairing.G1Point(
            2836547022425044839446597422595984953559741793057146651032784897916670862069,
            14680012359072743282778864393068598563840082316045178716989359524680577165475
        );
        vk.IC[61] = Pairing.G1Point(
            18393769942279282096214366696214413150699038871158688647211565624514527849392,
            7981636551400248764661025095601068852514128948613622986065038662691862387376
        );
        vk.IC[62] = Pairing.G1Point(
            10161078628644772598592962445722855578830661774777967820495819026431002518978,
            4370368967094023783400667941476469380409134561441586711173238550029390078353
        );
        vk.IC[63] = Pairing.G1Point(
            15991382879423061578448912025088146061472641152821240476698212938417185043590,
            18528810281409510059333307827296819647613027561293767272468138362600263910549
        );
        vk.IC[64] = Pairing.G1Point(
            13488558318757673080630118417722258367210955494845688715526714694383764632691,
            10768365596290933051792097181200388080820860152849956405537111876553748533095
        );
        vk.IC[65] = Pairing.G1Point(
            6294570834404379157120404560626050945001702167718369151449240697461399207765,
            15262692464738031660590757261876215632944396848801632595263420988013425649164
        );
        vk.IC[66] = Pairing.G1Point(
            5254670366770595355569466561966025019365199127587454188257730813806778861067,
            5639616150685136047185423867058269716038127649009044566452559645581371798232
        );
        vk.IC[67] = Pairing.G1Point(
            2400100796099387260745572593392152325140535099144522997314085534858057202680,
            10533470923933987502111425539154459595857278505795487806706476804277800520038
        );
        vk.IC[68] = Pairing.G1Point(
            12935282714460277342114665201409752315488661294431207384670060552874438335158,
            828501777107482430943914474918568920393042113401745586134081630861783455815
        );
        vk.IC[69] = Pairing.G1Point(
            3618107037133662130747042116616178538201174837185816495502426503643421771480,
            9810304793163420473046485569772617330611338546359940735484483613688208767100
        );
        vk.IC[70] = Pairing.G1Point(
            11847365271961743112246538565264415572626267982126675499909493380730378601211,
            14443215701231430129607739720838768432913949491784252387386453049974072161304
        );
        vk.IC[71] = Pairing.G1Point(
            19379915436956259538203796966944433337314602904685604687960094736042649548850,
            21731282089782595946507974582620161483135781361201699367390693612118206763166
        );
        vk.IC[72] = Pairing.G1Point(
            8670582306602957602139524430520615232224626571924879767989932788601657839705,
            20240028149930178111462288386187661110065256257878495499833413530580948192186
        );
        vk.IC[73] = Pairing.G1Point(
            19262157674978253529639757124209766280653698409733333105849034575557766075911,
            18725662471334144719357179778861522927362841480715456595808944062597734164275
        );
        vk.IC[74] = Pairing.G1Point(
            11937351694275207805677793096189119640182395483145378829494130992045932932402,
            5149272607548704818551955758867493163087655822305808745009971890956465302791
        );
        vk.IC[75] = Pairing.G1Point(
            11285338166073136340379912263641508759210185975865523694926277700656594983644,
            5262459907463066682994761139940562703101782582158732741180946102279509050491
        );
        vk.IC[76] = Pairing.G1Point(
            14994531650932758871093989350546205547229807289967028407117565052239974368698,
            14979877544220660228096614568276545551309086537594372178701202957917993083782
        );
        vk.IC[77] = Pairing.G1Point(
            18931373465063016006121147683817814466552635911668031136571217299991600857607,
            20616092188597992274873866725265078081992714549906685698186638821742655966006
        );
        vk.IC[78] = Pairing.G1Point(
            16223759085688278400243737214298940025086302967245013976512729188869096169439,
            8000347989417858696194529542521801256538999085466241451994717760398357025237
        );
        vk.IC[79] = Pairing.G1Point(
            623443864713442841981849089448604141181773933775966914579776605230250032497,
            2379999033595175627263823931205226554474139461391422077483569058966826408345
        );
        vk.IC[80] = Pairing.G1Point(
            21226775635762391344854052525875686072078791247455126973907668311431835458639,
            17027178338091034635381390209421024984033427567419893813056709396110422687589
        );
        vk.IC[81] = Pairing.G1Point(
            4406531262486869929739147572658540207438262627402337401159835776875728663789,
            220385918634829015545468867180066353049242465866175752563162610148191013434
        );
        vk.IC[82] = Pairing.G1Point(
            9797207478561423315143138309744701334893639486137377802308890232992477513720,
            2586950816627416917451641234260253308949163330009005231120465814213477098084
        );
        vk.IC[83] = Pairing.G1Point(
            15309200365081882408231201087428425254163549204077840425964328690772346033670,
            1420653871088013895417137322639493713879329388707684458719358558188436055909
        );
        vk.IC[84] = Pairing.G1Point(
            5395748123924977912477727326786701019012034070214199738229322577914878760547,
            7628200684351438536743882074776075848369438315729954233891518806298773543307
        );
        vk.IC[85] = Pairing.G1Point(
            352873088429432859429827976930730144447342272143569996853788758955913360951,
            13557940319268929136671986360637249073021349865497838232871747533161773674948
        );
        vk.IC[86] = Pairing.G1Point(
            20390847446322870632012348429141050569716681622655209013227534192933040047286,
            16601725957725371315244958994186136321295718657589978469349981368781290668594
        );
        vk.IC[87] = Pairing.G1Point(
            10171244392133486272864208287484656347521017906039416227854049812946279320105,
            2630827206962916085171272711240866826225252545527472551573751508980174876091
        );
        vk.IC[88] = Pairing.G1Point(
            16352531007904215608094300232648495143595817948682623907427871458784950883796,
            16993693916466767903607317444132484836266649207098497892404903026424443571716
        );
        vk.IC[89] = Pairing.G1Point(
            603223061726511291440476385657363196101553796742553306946625645081493057269,
            13685063534092212994103810927659411074476571548106779360960364193910339420723
        );
        vk.IC[90] = Pairing.G1Point(
            20482788618592301804362137780552543066760313879343668976341131329158666578335,
            10119970067501433949931252516195299415177432098847426604939527819895209325599
        );
        vk.IC[91] = Pairing.G1Point(
            2286917222416974411137929857213038335498658734765087792683880526591855212682,
            8386238751216926859196104203141517321604366389861372745269174839337885898975
        );
        vk.IC[92] = Pairing.G1Point(
            15324926480317494716032023374514633735806847765119736427811010194963001692421,
            10189091463447429155875471067647784384205623678977633060470897435180531628153
        );
        vk.IC[93] = Pairing.G1Point(
            19735006490529947214832901256389474816550406461720124117769379813998530963613,
            19195008944688234958527214663405723410047176990567036258258453159107662227963
        );
        vk.IC[94] = Pairing.G1Point(
            3773047036482552425932436266063563132694524670151434200639461194180781141756,
            1123197365687992723762170002716778183937672523336845843814102502661718722217
        );
        vk.IC[95] = Pairing.G1Point(
            14790301436962306445742567184681328955778087717603783082398421514413106175959,
            3664262733113936439151537901275565274617302021345114406122049344244233132731
        );
        vk.IC[96] = Pairing.G1Point(
            7495743442452609231032661340728478229362466212014591137686159112363208668777,
            10251074652941314300740989711880914433717637456150656228254458047351225953486
        );
        vk.IC[97] = Pairing.G1Point(
            12991196094489557947450463221167441136828652071786536768418099339232436003142,
            2681647771395556588691524032966418546665225547190996070629047477265207346855
        );
        vk.IC[98] = Pairing.G1Point(
            17954690883096938828060234193965975290699093120389901540291552765387478654653,
            13949701574189136535120046399140852023755864585250094436654725028812386703504
        );
        vk.IC[99] = Pairing.G1Point(
            6026273861623455551050623210276804173703022085693153508904372896159829096394,
            1781686254775648768045384902355242197382883159277642260121721641318534031512
        );
        vk.IC[100] = Pairing.G1Point(
            2883336496924528435374250979286473163150430963168096134363354458270160268956,
            6830892926711966851101701577055790982801152188763943324837126760195364273175
        );
    }

    function verify(
        uint[] memory input,
        Proof memory proof
    ) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (
            !Pairing.pairingProd4(
                Pairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }

    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[100] memory input
    ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for (uint i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
