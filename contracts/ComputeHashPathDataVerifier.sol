//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
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
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
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
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
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
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
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
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
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
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
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
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
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
contract ComputeHashPathDataVerifier {
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
            8975200139137680326537315640903298764240966659913302774219199787784839890746,
            18918103695192043224561275999785871250349745983763714554452227384706535599218
        );

        vk.beta2 = Pairing.G2Point(
            [10507076799693754277342299610883221342455370125701534989585604406444248460586,
             11138084488718045907097424010827096951539532146970121877800163102538937365126],
            [10358410162609335113119458381526034341309899576968486459646063181991922201864,
             529324185255923006029450586357433426066092575823694765129234273017526751567]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [16239796213936581576278405918138688158754501547987497628457986817672976688785,
             19847114241177350705322977681643079266915986431948633301190855842568654600255],
            [6182531180118821590100097188713346172522167901656153466854091949998522789614,
             5654957927447453679428706234169482756365433435444604475329826095054831813976]
        );
        vk.IC = new Pairing.G1Point[](102);
        
        vk.IC[0] = Pairing.G1Point( 
            12421031618647416173901446564540373459425654768044845392332733094869690777316,
            4994799953116800428085613926331878426045453585653577789287881430384845666882
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            12918612768012093927034284719417865043439902186527081080670464765278821596878,
            1601751884378993411993465881044758328625174361200172728021353511901784781180
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            343756855093656447339076608940290175193715412024730380519175051143695633778,
            6418604295214979666847591546533297518147135543612407764827373260850221223658
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            18990723711466980005007362716344434192631578340016546811429137863706590194738,
            857135315530324082359223898561395171798834965676917954503773184067870335223
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            11765941808152909009669288096136367556544931996679586883822765717589395010772,
            12610901019673886500903168970847642305711654506516755862424271291738024928463
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            8239074086542334646383930056412106857123307149840100962089329623603621101963,
            12058642277408947472997061970363038137083224555787005238510026689268316404093
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            19428826431841459875197182553657985587967401789535630823337424371598489487252,
            18852909596976739963743043889762951790518852233118207625414491985065600946992
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            13746382123297300635608905612484995472509732768851560851648852303422840124986,
            21560151806907442519251597668809396608168907963404854734839127711065407379665
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            13179524277829670783034431492411530223004157725304468853090661765592571482485,
            3910275391208575883609768292750669655471261458737045779302390811702882635946
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            791694119842041048165459360520548841082415295736858523360974534170173509215,
            19399516078386754893805181928132849638111188489665495936359174117506607835498
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            5475305757553554106463165980118913822135933480903414383688079699110727922303,
            10042448407224364470535506166809990059242596790092790481487046116448457170388
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            11283027622879481229828794720381203985974427415837999577664195086263673293351,
            5300362470480825700739754090523140873619985717200344997435921676216376520902
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            492503751079145025402648729259720369056552442900564939508648463562322164568,
            4785928325067960050631602890573339324779536829045260799786485350008286565684
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            4625184895667647714107644160867264448422302751373178926409359061599709987882,
            17356343928508288573715313844837945476426969716260218306056794718689539722638
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            473922138243363043139503664574060006446492392284612395438624895087485861996,
            17119723732083449532121587941731961068378944157820053208104433510134156424859
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            18838921791495680610609204133566817990049355554868840596114834429895169290430,
            2281991732816775534436782113975164733927004394812761552718292989984116134143
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            8296431119880794018267513442665940166153643153234128234976465054319623305540,
            10443444251385646033987201006841545689824038521364120433025749697091414004159
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            13678339343022371073348913443564893089050962708900597720682248132435256315709,
            20302027244630334879777083718357920373747827838879987361117590831936858806866
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            5360731056669647956907523579093350788617684923030510561841150506442755909050,
            5714268740486009770429349447396084834630195621163763280988538846555817171264
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            2669204895346037400979268679663787906560839188732944252058856379698232369918,
            10496297025490987102209100904407240971373223821752389968584127371540656920615
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            18329097475289100177180671965889769071826842279132456114068456945778830220987,
            745066720212065310388355727708966172943754045073943701499769562390554169417
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            6883803630692928834611607916391504528950965047827664943995460727288860554389,
            3500500105718038874803524058552139885541428764578360899884819414258266961548
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            12715143197292373316853007303458490528609903340373809853629699131625348849299,
            10919827647521500856137532072096087671774487313067709944115671901939795379385
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            8633198308987063133351311979471787437318271336703224798331455386719333615073,
            2870327022950688736556388954490079398911688628915583167131967654004582542305
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            16485105447451554539692679463626394804422841674643142706522693544875340799585,
            21518923510035706198106410045936392075867676614466974059525786774361022384394
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            3731708738646006054963356421108242612826964923660894527383471536757798451356,
            6395104772914889578871841297927596520420758661333149846711335253303154128148
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            8368369237783879952027412519199051558078171044995647853779803426450374079201,
            2750024737512633147135163077672454779878278353600698683753457477467158651234
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            20780469531022975598499715008562892451112218129957966565423897743051897018011,
            10426821188720422951391002007116287292909927694458390883053143649989794820686
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            3754051914092194774607153706963142836729655116163495348856600350740847502847,
            13036522120754758019482487614383426756643167435250799808679569575916135971468
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            631186398492363636477573753534024643356405617072925583093388649672473364487,
            11968505941194836712604170502148183417982287612876913205356608157825861878651
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            3038460873822227003022860629419396391845081963499741661859206003872686542775,
            16529228901549073026405751469157097063237041557126603425190620026376317367920
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            11827300356817142718013664777563233191122098077059971206208021860882846584780,
            10685377535655624499462763484155528014436736624266090847591424108590092896427
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            17924850836981367871334392284032913426566895044331403123165720276944514630506,
            4228613432623071089520033848833336034393679887505170071671490510844698722747
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            6095082789795503189528318414043190059444927071044278311379020449299393696581,
            2521918404490041713635529774256757802556760281023048167138492691057442398474
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            8526894959690417683028957421041979021344319433213031149006615050770336568530,
            18968227051768385790089157210415640275944133246417440825386508439905521861688
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            14500378308631932405771180464908934367333079839846577367412307270518065956337,
            3051240653722834935782159120441162675652312542898004774803238178827994489853
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            11874224329985658458311466655490088446952579668994446968610962981847169581837,
            20649897607393206813221071667265639407572757189432896419335374113164813456652
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            9756495851978047864046712486821576377076148684335092878297651440009316663957,
            13919497198401460057444793099190120090144709228431875309011397308187119433942
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            1343753489244064605714321982033250281565120533027615086555785463722684415032,
            2728481269677252394226305094764646508355741212142268309084185590245037494775
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            18709457774495581749686748009826239196568613008894023341183741311432204482227,
            18752169545973260349801456389778770342765747257942140674727181018545910064828
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            15272535621198861070131340227402537714604195653520900129139358373770469834395,
            21557887547731126752274893004585964697389715033619911211036077636074615351685
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            14658406239709689126162620874939919595765791848614662986290922972817346407922,
            17112548301787440992286107606855328766870410148293081322880670375939011127066
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            8112063981193484978858790877994574204806427728693449484478942788760841572401,
            14354986175221701106677073519670525457143730635078300630454043308084228607368
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            20394700222238694879181161936655819356977419794128947261697753299413836279226,
            20396210306594165204790248543797745500413699628663183880157796061630441818553
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            10631182532164492436920248005166270001525803716777857885664067163071710799416,
            17583816743748550885714630979705268644374721313981910480781951500106221312475
        );                                      
        
        vk.IC[45] = Pairing.G1Point( 
            7796805038454622153764588292608962299381426660522368854062232980643166153846,
            12413388439434647278657436837605556515092066228515859700877042284577765971388
        );                                      
        
        vk.IC[46] = Pairing.G1Point( 
            21718411791423614806763933238850442075236101464546100152496688418723340568515,
            2967258255735277165837805025226992761768602451886217553590524257279057181370
        );                                      
        
        vk.IC[47] = Pairing.G1Point( 
            21757660563445281234534953407244161828576905413515038346948070843405958432683,
            21845416818764178026154398982252615599060758133622330133493305720234395839682
        );                                      
        
        vk.IC[48] = Pairing.G1Point( 
            400203704724402125896077616217835789365952048176536831487492622605882165956,
            16750991068755130369133616972504504003428317237761326230338460226266817953155
        );                                      
        
        vk.IC[49] = Pairing.G1Point( 
            6117105008807847572131382496154642744223695108719798722245575420273926548398,
            1058796605757107261112661022365157197274919015835220471652188647421435378596
        );                                      
        
        vk.IC[50] = Pairing.G1Point( 
            6428611510178423046522650263191524570705170129823855970926981163811793697962,
            12447303059634282708578982310061084849831593155114577644018252797550308266133
        );                                      
        
        vk.IC[51] = Pairing.G1Point( 
            19407519926040573591991717135704946167831844261593839087243599759486418080979,
            4768567128058759953700678999216386425982049810568010891896608594624217616290
        );                                      
        
        vk.IC[52] = Pairing.G1Point( 
            14330620759105389730918673286810731905613296145404846869599649774692197335550,
            17966842458280449002687364318606937824785383653549315377709786812870459532975
        );                                      
        
        vk.IC[53] = Pairing.G1Point( 
            10703711296789114487152958609440440805106070852582912953297089050624978985940,
            6962140607033667349760231120015166889142411025248668171321415490016816518442
        );                                      
        
        vk.IC[54] = Pairing.G1Point( 
            4940835694161724634190051119073432868763633816124940258980540115688668927938,
            2945082592931975667888969100521606478743967640281590394987873295431997426461
        );                                      
        
        vk.IC[55] = Pairing.G1Point( 
            14324370402690090990401784157637001444941267713307772573711767887373220838335,
            7726509789038186752656682937518116625125055756396036746132699396423571438566
        );                                      
        
        vk.IC[56] = Pairing.G1Point( 
            9687810202614673624942491519180091412766099617137887348909286596981112850070,
            12949281592024570664447814866297337468287517778075950397532370514494690098429
        );                                      
        
        vk.IC[57] = Pairing.G1Point( 
            15374068776550295240751074794089628334704194930559019668312372318223715414572,
            12220211117412873663661340514175452648069108814586183532764687913590536601724
        );                                      
        
        vk.IC[58] = Pairing.G1Point( 
            6769511203127530983846720346102644604659454978176947760412132276594250474915,
            2578970529108455761878910792330016311053242145746024605998563750421022290479
        );                                      
        
        vk.IC[59] = Pairing.G1Point( 
            14004274222550464287224249057761576194974800600298186789922294563987021905177,
            8921729223788218608547746335410739551829744314458034391686820547294883773825
        );                                      
        
        vk.IC[60] = Pairing.G1Point( 
            20220188425994110579029181776055182555760792468773716842650430970526926643187,
            2186785715690588837719188433191929799629667630521475127091004401432892800657
        );                                      
        
        vk.IC[61] = Pairing.G1Point( 
            20172401006518468264069730572332830568844616559523387620667833212474464019514,
            10833901835788697998573559452973431206089901645856473793083709972996173641299
        );                                      
        
        vk.IC[62] = Pairing.G1Point( 
            3286383184107796082224048816934001097746249978891443666719670210052848329398,
            17845079906779099317989571895617947061978808327046632460828865487146034206027
        );                                      
        
        vk.IC[63] = Pairing.G1Point( 
            9769100037424057467660756839357765026062406120326442888149709807436616864307,
            18873316792172502108528273609062011739978702753243494856671061987440750954663
        );                                      
        
        vk.IC[64] = Pairing.G1Point( 
            8135800151071209420520010390981512291424743508128929260861369636984361740683,
            21862127486892607685438018221513832402572891337604477907650955095551521139927
        );                                      
        
        vk.IC[65] = Pairing.G1Point( 
            8092751574834344954098818937480983045425857678866871135433096556376913167522,
            17918692984570485292442994621612973541778792650376847184043068944291196667350
        );                                      
        
        vk.IC[66] = Pairing.G1Point( 
            17446549964317166565200789811916753971181023330946700656374103871866067989513,
            13982714637248389236373225415620343357154850934987936646586027589356223187199
        );                                      
        
        vk.IC[67] = Pairing.G1Point( 
            255952445423735690885715962918950859104053280031814736786780678284722292347,
            18760986046060712160822708952242472313517085855987701774796929211558749695721
        );                                      
        
        vk.IC[68] = Pairing.G1Point( 
            21018130188195585446368661012937357336443526704737603666287149000854123170833,
            3202196583751872752853615786048188733373423622954788358226236724084121763678
        );                                      
        
        vk.IC[69] = Pairing.G1Point( 
            19457267893763077683406705619307672676172827075263127723491264404651870636011,
            1164482389907700789619795386171889055935511914296890390986249242078904266077
        );                                      
        
        vk.IC[70] = Pairing.G1Point( 
            21517928681549509562191974709509508773645951031465503930933132525072866309679,
            18255489786803649364149628320533759417826327167190180256315663647631775047227
        );                                      
        
        vk.IC[71] = Pairing.G1Point( 
            6950820074905543294059566818647010169121479268941001991816190334639196973405,
            15185947777790745395175301271336707438622036053871396303943063338839075839916
        );                                      
        
        vk.IC[72] = Pairing.G1Point( 
            7271554091526269959637188356880129320228961414070114468151351817121075516853,
            11010386964830246972606646275974167215333981902191667470525125497801097187519
        );                                      
        
        vk.IC[73] = Pairing.G1Point( 
            7754641539899415940478709828654464259021312545835172261169918210062613226630,
            8488941510925111730699077597603489784421193925101340210664638946226125087473
        );                                      
        
        vk.IC[74] = Pairing.G1Point( 
            10491812237390441061924494196219670364447753728138950315878104516479853359685,
            10918956884610474114957080986383507761723002301059347293694384205605643513248
        );                                      
        
        vk.IC[75] = Pairing.G1Point( 
            8125570718457336373733763441501918030139220427644838752380301648437831262659,
            4224907337611051517315384418802300050856648702138410632350425270117126905902
        );                                      
        
        vk.IC[76] = Pairing.G1Point( 
            10209123816961451792208646854634813067281457627846073036139283286892174841960,
            3694452786683241209178986647340712131155390318268937112555812463044733738891
        );                                      
        
        vk.IC[77] = Pairing.G1Point( 
            13903891221749397616122168945815557245764640548094512735129337180132393137107,
            5965481599150666968469696973889775838208819596619950662509301873404648044166
        );                                      
        
        vk.IC[78] = Pairing.G1Point( 
            3826983163658588234731008018660323344829167218506043574553373656017186428760,
            21543538649759633850463397377146779803144168555910944179762277194794106192180
        );                                      
        
        vk.IC[79] = Pairing.G1Point( 
            10002263975081496655541936683663889106332141903010288490155575937514403232803,
            18848313907032890883767846205780657696008786543001071021681075871409165670353
        );                                      
        
        vk.IC[80] = Pairing.G1Point( 
            15001806022679623892982343095208980454221635962571458607940631019391998772628,
            15578120282428824490566499216659073443445325481926684639256039508593954049833
        );                                      
        
        vk.IC[81] = Pairing.G1Point( 
            2209335672569870843205707262494552613378185002865168486470950014530344359190,
            9913770270111388606233528313318329755692498084320429956312534548647703582945
        );                                      
        
        vk.IC[82] = Pairing.G1Point( 
            17291460706805477205827783605257311819759009608661942070554086540521022286330,
            10751471050262610580501517306980466146405347621120660882898046623051382739921
        );                                      
        
        vk.IC[83] = Pairing.G1Point( 
            13289192160985029552663955929045469166277240690721607529449458569072816445255,
            12259238517085581143064728486457005116263916311944044414137180311597935623363
        );                                      
        
        vk.IC[84] = Pairing.G1Point( 
            1592691847390195395005289997893788771468192103724717236266156856088459289000,
            3126802691599201532602069819319676562550281625372565175753400518057235693656
        );                                      
        
        vk.IC[85] = Pairing.G1Point( 
            735135443491828395996108495615194879193721581556720627221441562028841708301,
            18254477793665952697827037314634956931060931229242992664425997480943732613553
        );                                      
        
        vk.IC[86] = Pairing.G1Point( 
            9242115661072705623648734481411182414435910213243762316733173195057520465442,
            927072760387387503555849148158078601623466704859557232958326442122288858975
        );                                      
        
        vk.IC[87] = Pairing.G1Point( 
            14646056149031854086542526377727240881212144054407593374243914855374187767963,
            12266348506664616841386636578246077132505805959594146818505631557265938988647
        );                                      
        
        vk.IC[88] = Pairing.G1Point( 
            6396947530776650621477423520872419772982104259669452150077826579839156076121,
            11502074903892296042115772020000414018151060173842165079298881449297869111093
        );                                      
        
        vk.IC[89] = Pairing.G1Point( 
            10946458993881688986927910849481816324454831526049095539176357327854971977618,
            5692818236250065107490913399811852971385472931605448960212600323056773937804
        );                                      
        
        vk.IC[90] = Pairing.G1Point( 
            5777442726397972906681258157409862284692232787027336502064129262833253540409,
            12533488525293962978676494933040117446619736710995709081080469674702977790482
        );                                      
        
        vk.IC[91] = Pairing.G1Point( 
            5253658426948807364571717351072864573097112295745981584649406240362624378918,
            16811126459496552866567782559121469319150754895919957692371210903337575653834
        );                                      
        
        vk.IC[92] = Pairing.G1Point( 
            9602753227541606409911146775967175075625339391448087840066817828641587636765,
            9992882341621694715683807221842979278421697535144085289594997444399549116168
        );                                      
        
        vk.IC[93] = Pairing.G1Point( 
            1402568322771326539085966935087005624058494724115881159780851211976864740087,
            475793255298171503728520410214522450122388987052008115259161370363899104447
        );                                      
        
        vk.IC[94] = Pairing.G1Point( 
            15520244790226117846707091428618536020270792822939864015212827184472691195573,
            6084708761749386809985953238814961793337317156208941708886742143232564812445
        );                                      
        
        vk.IC[95] = Pairing.G1Point( 
            5228694409995254722369882121605748123939696500105732381189014387420165260170,
            16952920147313636751804325201522565744101824197551177951684097769956356271712
        );                                      
        
        vk.IC[96] = Pairing.G1Point( 
            10668433651157538865191748155076735007768484178924302838807969926910616240251,
            17144590972545034388458235202739540750102764818675045257313430939106746975751
        );                                      
        
        vk.IC[97] = Pairing.G1Point( 
            4011091409147594665360535878092673147928271216285510111814690599135897646191,
            17469434003490378296288505629224604970046655324385307335636439388441543092770
        );                                      
        
        vk.IC[98] = Pairing.G1Point( 
            9404339739165816773340307993266662769269221628192961178507054986822178091525,
            14974248693367524032521771630573501588254271542779502382006360348071875912055
        );                                      
        
        vk.IC[99] = Pairing.G1Point( 
            17907477305132533964571060626210295793245498381532345054587580964822814250710,
            3848316766381221894581011575558460489976597468540610173016827298779408501383
        );                                      
        
        vk.IC[100] = Pairing.G1Point( 
            2876152813496217087804330597545291376553798873490855245373258212041487041797,
            13305189393049483303052417781507503995004491886129167867898581795055152838916
        );                                      
        
        vk.IC[101] = Pairing.G1Point( 
            11246966281387345597806396035626423475469237820576907343787118407989912004004,
            16693969610457620338447472354729408304700012063027235442839447127296083817625
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[101] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
