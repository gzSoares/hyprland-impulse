## Fedora Bootc Hyprland + Illogical-Impulse Shell

Este repositório contém uma imagem personalizada baseada no fedora-boot imagem oficial, usando o conceito de sistemas imutáveis com bootc.

A proposta do projeto é ser simples e didática, ajudando iniciantes a aprender como criar suas próprias imagens de sistema personalizadas com bootc.

## O que acompanha a imagem

</details>

<details>
  <summary>Software overview</summary>

  | Software | Purpose |
  | ------------- | ------------- |
  | [Hyprland](https://github.com/hyprwm/hyprland) | The compositor (manages and renders windows) |
  | [Quickshell](https://quickshell.outfoxxed.me/) | A QtQuick-based widget system, used for the status bar, sidebars, etc. |
  | [Illogical-Impulse](https://github.com/end-4/dots-hyprland) |  |

</details>

</details>

<div align="center">
    <h2>• screenshots •</h2>
    <h3></h3>
</div>

<div align="center">
    <img src="assets/illogical-impulse.svg" alt="illogical-impulse logo" style="float:left; width:400;">
</div>

Widget system: Quickshell | Support: Yes

[Showcase video](https://www.youtube.com/watch?v=RPwovTInagE)

| AI, settings app | Some widgets |
|:---|:---------------|
| <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/5d4e7d07-d0b4-4406-a4c9-ed7ba90e3fe4" /> | <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/6a32395f-9437-4192-8faf-2951a9e84cbe" /> |
| Window management | wow look its orange |
| <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/c51bed8b-3670-4d4c-9074-873be224fb8e" /> | <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/98703a66-0743-439f-a721-cef7afa6ab95" /> |

<div align="center">
    <h2>• thank you •</h2>
    <h3></h3>
</div>

## Base da imagem

* Base: `fedora-bootc`
* Compositor: Hyprland
* Interface: Illogical-Impulse Material Shell
* Sistema: Imutável via bootc
* Distribuição base: Fedora Project
* Formato de distribuição: Imagem OCI inicializável
* Instalação: ISO personalizada inclusa no projeto

## Estrutura dos arquivos

| Arquivo                | Função                                          |
| ---------------------- | ----------------------------------------------- |
| `Containerfile`        | Define como a imagem é construída               |
| `pacotes_desktop`      | Lista dos pacotes do ambiente gráfico           |
| `pacotes_necessarios`  | Pacotes essenciais do sistema                   |
| `post-install.sh`      | Script executado no primeiro boot               |
| `post-install.service` | Serviço systemd responsável pelo pós-instalação |
| `config.toml`          | Configuração usada para gerar a ISO             |
| `locale.conf`          | Configuração regional pt-BR                     |
| `vconsole.conf`        | Configuração do terminal TTY                    |
| `zram-generator.conf`  | Configuração de zram                            |
| `.github/workflows`    | Automação de builds via GitHub Actions          |

## Atualizando o sistema

```bash id="yq8yxv"
# Verificar atualizações
sudo bootc upgrade --check

# Aplicar atualização
sudo bootc upgrade

# Reiniciar o sistema
sudo reboot
```

## Comandos úteis

```bash id="yq0x9j"
# Ver informações da imagem atual
bootc status

# Voltar para a imagem anterior
sudo bootc rollback
```

## Aviso sobre bootc switch

Agora é possível realizar o bootc switch diretamente a partir do Fedora Silverblue para esta imagem.

```
sudo bootc switch ghcr.io/gzSoares/hyprland-impulse:latest
```

## Clonando o projeto

```bash id="66d9r8"
git clone https://github.com/gzSoares/hyprland-impulse.git
cd hyprland-impulse
```

## Build local da imagem

```bash id="i8ls7u"
sudo buildah build \
    --skip-unused-stages=false \
    --security-opt=label=disable \
    -t "hyprland-impulse" \
    -f Containerfile \
    -v $(pwd):/run/src \
    .
```

## Gerando a ISO de instalação

```bash id="eolam0"
mkdir -p output

sudo podman run \
    --rm \
    -it \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v ./output:/output \
    -v ./config.toml:/config.toml:ro \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type anaconda-iso \
    --rootfs btrfs \
    localhost/hyprland-impulse
```

## Download da ISO pelo GitHub Actions

Este repositório também gera automaticamente a ISO através do GitHub Actions.

Para baixar a ISO gerada automaticamente:

1. Abra a aba `Actions` do repositório
2. Entre no workflow desejado
3. Aguarde o build finalizar
4. Role até a seção `Artifacts`
5. Baixe o artefato contendo a ISO

## Credits

- **[Fedora-Bootc](https://docs.fedoraproject.org/en-US/bootc/):** Base system.
- **[end-4](https://github.com/end-4):** Creator of illogical-impulse.
- **[Quickshell](https://quickshell.org/):** Widget system.
- **[Hyprland](https://hypr.land/):** Compositor.
- ** Um agradecimento especial ao [Ferlinuxdebian](https://github.com/Ferlinuxdebian) que me ajudou na realização desse projeto. 

# 🚀 Sobre o Projeto

> ✨ **Este projeto foi criado com base na minha experiência de uso.**  
> Mas sinta-se à vontade para explorar, testar e adaptar da forma que fizer mais sentido para você. ✨

---
