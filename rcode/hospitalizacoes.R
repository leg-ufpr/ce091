
if (FALSE)
    setwd('..')

library(read.dbc) ## ler arquivos de dados .dbc do DATASUS
library(sf) ## biblioteca para trabalhar com mapas
library(maptools) ## alternativa, para funcao leglabs()
library(leaflet) ## visualização alternativa de mapas

### Dados de internacoes Paraná, Outubro 2016
### http://datasus.saude.gov.br/
### <Acesso à Informação> + <Serviços> + <Transferência/Download de Arquivos> 
### <Acesse o SIHSUS> 
### Seleciona "Dados", "RD - AIH Reduzida", "2016", PR", "Outubro", <Enviar>
### Clicar no link
### link direto: ftp://ftp.datasus.gov.br/dissemin/publicos/SIHSUS/200801_/dados/RDPR1610.dbc

s <- read.dbc('dados/RDPR1610.dbc')

## ANS LINK para dados disponíveis
### Dados abertos da ANS: http://dados.gov.br/organization/agencia-nacional-de-saude-suplementar-ans
### Hospitalares: http://dados.gov.br/dataset/procedimentos-hospitalares-por-uf
###   PR direto: http://www.ans.gov.br/images/stories/Materiais_para_pesquisa/Perfil_setor/Dados_e_indicadores_do_setor/tiss/hospitalar/PR/TISS_Hospitalar_PR.zip
a <- read.csv('dados/tb_TISS_PR_1610_H.csv', dec=',')

### numero de internações e número de variáveis
dim(s) 
dim(a)

### nomes das variáveis
names(s)
names(a)

### valor total
sum(s$VAL_TOT)
sum(a$VALOR_PROCEDIMENTO)

### Numero de missings por coluna
na <- colSums(is.na(s))
sum(na==0) ## maioria das variáveis sem NA
na[na>0] ### muito específicas

range(s$VAL_TOT)
range(a$VALOR)

table(cut(s$VAL_TOT, c(0, 1, 5, 10), include.lowest=TRUE))
table(cut(a$VALOR, c(0, 1, 5, 10), include.lowest=TRUE))

s$l10valor <- log(ifelse(s$VAL_TOT<0.1, 
                         s$VAL_TOT*0.1+0.1, s$VAL_TOT), 10)
a$l10valor <- log(ifelse(a$VALOR<0.1,
                         a$VALOR*0.1+0.1, a$VALOR),10)

range(s$l10valor, a$l10valor)
brk <- seq(-1, 6, .5)
sum(hist(s$l10valor, breaks=brk, plot=FALSE)$counts)==nrow(s)
sum(hist(a$l10valor, breaks=brk, plot=FALSE)$counts)==nrow(a)

### Visualiza o valor total por procedimento
par(mar=c(5,5,0.5,0.5), mgp=c(4,1,0), las=1)
hist(s$l10valor, breaks=brk, col='gray', dens=100,
     main='', xlab="log 10 do valor total",
     ylab='Número de Internações', axes=FALSE)
hist(a$l10valor, breaks=brk, add=TRUE, dens=40)
xlabs <- ifelse(brk<0, round(10^brk, 2),
                round(10^brk)); xlabs[1] <- ''
axis(2); axis(1, brk, xlabs, las=3) 
legend('topright', c('DATASUS', 'ANS'),
       fill=gray(c(0.5,0)), dens=c(100, 40))

## Mapa do Brasil dividido por municipios
br <- st_read('~/maps/br/a2016/BR/', 'BRMUE250GC_SIR')
names(br)
head(br, 3)
table(br$uf <- factor(substr(br$CD_GEOCMU,1,2)))
head(br,2)
plot(br[c('geometry', 'uf')], border=0)

### Seleciona municípios do Paraná
str(id.pr <- which(br$uf=='41'))
pr <- br[id.pr,]

### hospitalizações SUS, valor total por município
mun.val <- data.frame(val=tapply(s$VAL_TOT, s$MUNIC_RES, sum))
dim(mun.val) ## 567 municipios
head(mun.val,2)

### 2 digitos (UF): municipios de cadas estado
table(substr(rownames(mun.val),1,2))

### adiciona codigo com 6 digitos como coluna
mun.val$cod6 <- rownames(mun.val)
head(mun.val,2)

head(pr$CD_GEOCMU)
pr$cod6 <- substr(pr$CD,1,6)
head(pr,2)

### join dados na tabela de atributos do mapa
djoin <- merge(pr, mun.val, sort=FALSE) ### preserva a ordem do mapa
class(djoin)
head(djoin,2)

### opcao 1 de visualização default
plot(djoin[c('val', 'geometry')], border='0')

### log10
djoin$l10valor <- log(djoin$val, 10)
plot(djoin[c('l10valor', 'geometry')], border='0')

### opcao 2: construir classes e cores
(q <- quantile(djoin$val, 0:10/10))

i.color <- findInterval(djoin$val, q, rightmost.closed=TRUE)
table(i.color)
col10 <- rgb(0:9/10, 1-2*abs(0:9/10-0.45), 9:0/10)

plot(djoin[c('geometry', 'val')], col=col10[i.color], border=0)
legend('topright', maptools::leglabs(format(q/1e3, dig=2), '<', '>'),
       fill=col10, bty='n', title='Valor (mil R$)')

### visualização no GoogleMaps (iterativa)
### converte o mapa para a projeção utilizada pelo Google:
map.wgs84 <- st_transform(djoin[c('geometry', 'val')], '+proj=longlat +datum=WGS84')

### Visualização no GoogleMaps
leaflet()  %>% addTiles() %>%
    addPolygons(data=map.wgs84, color=col10[i.color])
