
/* Query estratto conto o simile */
SELECT A.codice, A.ragsoc, saldo, 
FROM associazione A
LEFT JOIN (
	SELECT codass, sum(importo) as saldo
	FROM pagamento P
	WHERE extract(year from P.data) = 2021
	GROUP BY codass
) as P ON P.codass = A.codice
GROUP BY A.codice, A.ragsoc, saldo

/* Saldo stagione estiva per esempio */
SELECT A.codice, A.ragsoc, sum(importo) as saldo
FROM associazione A, pagamento P
WHERE 
	P.codass = A.codice AND extract(MONTH from P.data) between 4 AND 9 AND extract(YEAR from P.data) = 2020
GROUP BY A.codice, A.ragsoc

select *
from pagamento

/* Bilancio delle spese FAIL! */
SELECT sum(P1.importo) as spese_stipendi, sum(P2.importo) as spese_esborsi,  sum(P3.importo) as spese_arbitri
FROM pagamento P1, pagamento P2, pagamento P3, Stipendi S, Esborsi E, Fatture F
WHERE
	P1.codass = S.codass AND P1.id_dipendente = S.id_dipendente AND P1.data = S.data 
/*	AND
	P2.codass = E.codass AND P2.id_dipendente = E.id_dipendente AND P2.data = E.data AND
	P3.codass = F.codass AND P3.id_dipendente = F.id_dipendente AND P3.data = F.data 
	AND P1.codass = 'JSDB' AND P2.codass = 'JSDB' AND P3.codass = 'JSDB'
*/

/* Query per la visualizzazione degli stipendi */
select P.codass, P.importo*(-1) as importo, D1.nome as Nome_Emissivo, D1.cognome as Cognome_Emissivo, D2.nome as Nome_Ricevente, D2.cognome as Cognome_Ricevente, P.data
from Pagamento as P
join dipendente D1 on 
	D1.codass = P.codass AND D1.cf = P.id_dipendente
join stipendi S on
	S.codass = P.codass AND S.data = P.data AND S.id_dipendente = P.id_dipendente
join dipendente D2 on
	S.soggetto = D2.cf AND S.codass = D2.codass
where tipo_operazione = 'S';

/* Sport più ricercato */
SELECT sport, count(sport)
FROM prenotazioni P
JOIN campo C ON P.codass = C.codass AND P.id_campo = C.id AND P.sede = C.cod_sede
JOIN tipologia_campo T ON T.codass = C.codass AND T.id = C.tipologia
GROUP BY (sport)

/* Tesserati che hanno fatto almeno 2 prenotazioni nel 2020 */
SELECT T.cf as codice_fiscale, T.cognome, T.nome, count(data) 
FROM prenotazioni P
JOIN tesserato T ON P.codass = T.codass AND P.id_tesserato = T.cf
WHERE T.codass = 'POLRM' AND extract(YEAR from P.data) = 2020
GROUP BY T.cf, T.cognome, T.nome
HAVING count(data) > 2

select *
from campo

select *
from prenotazioni

select *
from tipologia_Campo

