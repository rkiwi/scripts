import sys
# получение имени файла из аргумента командной строки
rackList = sys.argv[-1]
servers = []
rack = set()
file = open(rackList, 'r')
for line in file:
    servers.append(line)
file.close()

for host in servers:
    line_split = host.split('\t')
    # вычленение стоек
    rack.add(line_split[2])
rack = sorted(rack)

for i in rack:
    print('\n', i)
    for host in servers:
        line_split = host.split('\t')
        if i in host:
			# hostname и расположение
#            print(f'{line_split[0]} {line_split[4].strip()}')
			# только hostname
#            print(f'{line_split[0]}')
			# hostname, расположение и статус
            print('|'+f'{line_split[0]}|{line_split[4].strip()}'+'|(x)|')