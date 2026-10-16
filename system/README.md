# System — controle temporário de RNDIS

A tela consulta o estado real do gadget e persiste MACs e endereços de rede no
SQLite privado. Preferências não indicam que RNDIS esteja ativo e não restauram
o estado ao abrir o app ou iniciar o Kobo.

Antes de cada ativação ou desativação, confirme a ejeção segura do armazenamento
Kobo no host. O dispositivo não detecta essa ejeção. O gadget pode combinar
RNDIS e mass storage, e a mudança pode interromper o USB.

Após ativar, configure manualmente a interface USB do host com 192.168.7.2/24
para os padrões (Kobo 192.168.7.1/24). Não há DHCP nem encaminhamento para
Internet, e RNDIS não inicia SSH.

Ao desativar, o gadget fica desassociado e a função RNDIS é removida. Desconecte
e reconecte o cabo para o handler stock tentar restaurar o USB. Se o estado for
parcial, atualize a consulta e siga as instruções de recuperação antes de
reconectar.

O simulador Linux retorna device_unavailable. Testes no simulador não validam o
configfs no Kobo; qualquer teste físico exige procedimento autorizado.
