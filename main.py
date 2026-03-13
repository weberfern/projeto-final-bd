from decimal import Decimal
from sqlalchemy import create_engine, Integer, String, Boolean, Numeric, Date, ForeignKey, select
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship, sessionmaker
from datetime import date
from typing import List, Optional

# ==========================================
# CONFIGURAÇÃO DO BANCO DE DADOS E CONEXÃO
# ==========================================

# ALTERE A SENHA DO SEU POSTGRES DE sua_senha PARA A SENHA QUE VOCÊ CONFIGUROU NO SEU POSTGRESQL LOCAL
DATABASE_URI = 'postgresql://postgres:weber150@localhost:5432/postgres?client_encoding=utf8'

engine = create_engine(DATABASE_URI, echo=False)
SessionLocal = sessionmaker(bind=engine)

class Base(DeclarativeBase):
    pass

# =============================================================
# MAPEAMENTO DAS TABELAS DO BANCO DE DADOS PARA CLASSES PYTHON
# =============================================================

class Adotante(Base):
    __tablename__ = 'adotante'
    __table_args__ = {'schema': 'exemplo'}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nome: Mapped[str] = mapped_column(String(100), nullable=False)
    cpf: Mapped[str] = mapped_column(String(11), unique=True, nullable=False)
    endereco: Mapped[str] = mapped_column(String(255), nullable=False)
    idade: Mapped[int] = mapped_column(Integer, nullable=False)
    tipo_moradia: Mapped[Optional[str]] = mapped_column(String(10))
    area_util_m2: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    possui_criancas: Mapped[bool] = mapped_column(Boolean, default=False)
    possui_outros_animais: Mapped[bool] = mapped_column(Boolean, default=False)

    # RELACIONAMENTO 1-N
    telefones: Mapped[List['Telefone']] = relationship(back_populates='adotante', cascade="all, delete-orphan")
    adocoes: Mapped[List['Adocao']] = relationship(back_populates='adotante')

class Animal(Base):
    __tablename__ = 'animal'
    __table_args__ = {'schema': 'exemplo'}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nome: Mapped[str] = mapped_column(String(50), nullable=False)
    especie: Mapped[str] = mapped_column(String(10), nullable=False)
    raca: Mapped[str] = mapped_column(String(20), nullable=False)
    genero: Mapped[str] = mapped_column(String(10), nullable=False)
    idade_meses: Mapped[int] = mapped_column(Integer, nullable=False)
    porte: Mapped[Optional[str]] = mapped_column(String(1))
    temperamento: Mapped[Optional[str]] = mapped_column(String(50))
    status: Mapped[str] = mapped_column(String(20), default='DISPONIVEL', nullable=False)

    # RELACIONAMENTO 1-N
    historico: Mapped[List['HistoricoAnimal']] = relationship("HistoricoAnimal", back_populates="animal", cascade="all, delete-orphan")
    adocoes: Mapped[List['Adocao']] = relationship("Adocao", back_populates="animal")

class Telefone(Base):
    __tablename__ = 'telefone'
    __table_args__ = {'schema': 'exemplo'}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    numero: Mapped[str] = mapped_column(String(20), nullable=False)
    id_adotante: Mapped[int] = mapped_column(Integer, ForeignKey('exemplo.adotante.id', ondelete='CASCADE'), nullable=False)

    # RELACIONAMENTO 1-N
    adotante: Mapped['Adotante'] = relationship(back_populates='telefones')

class Adocao(Base):
    __tablename__ = 'adocao'
    __table_args__ = {'schema': 'exemplo'}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    id_adotante: Mapped[int] = mapped_column(Integer, ForeignKey('exemplo.adotante.id', ondelete='CASCADE'), nullable=False)
    id_animal: Mapped[int] = mapped_column(Integer, ForeignKey('exemplo.animal.id', ondelete='CASCADE'), nullable=False)
    data_adocao: Mapped[Date] = mapped_column(Date, default=date.today)
    valor_taxa: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    termo_aceito: Mapped[bool] = mapped_column(Boolean, default=True)

    # RELACIONAMENTO N-1
    adotante: Mapped['Adotante'] = relationship(back_populates='adocoes')
    animal: Mapped['Animal'] = relationship(back_populates='adocoes')

class HistoricoAnimal(Base):
    __tablename__ = 'historico_animal'
    __table_args__ = {'schema': 'exemplo'}

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    id_animal: Mapped[int] = mapped_column(Integer, ForeignKey('exemplo.animal.id', ondelete="CASCADE"), nullable=False)
    evento: Mapped[str] = mapped_column(String(100), nullable=False)
    descricao: Mapped[Optional[str]] = mapped_column(String)
    data_evento: Mapped[Date] = mapped_column(Date, default=date.today)

    # RELACIONAMENTO N-1
    animal: Mapped['Animal'] = relationship(back_populates="historico")

# ==========================================
# FUNÇÕES PARA EXECUÇÃO DOS REQUISITOS
# ==========================================

def executar_crud(session):
    print("\n--- Executando operações CRUD ---")

    # 1. CREATE
    print(("\n----------CREATE----------"))
    print("\nInserindo 3 novos animais...")
    novo_animal1 = Animal(nome="Bolinha", especie="Cachorro", raca="Poodle", genero="Fêmea", idade_meses=2, porte="P", temperamento="Dócil", status="DISPONIVEL")
    novo_animal2 = Animal(nome="Garfield", especie="Gato", raca="Persa", genero="Macho", idade_meses=36, porte="M", temperamento="Preguiçoso", status="DISPONIVEL")
    novo_animal3 = Animal(nome="Snoopy", especie="Cachorro", raca="Beagle", genero="Macho", idade_meses=12, porte="M", temperamento="Agitado", status="QUARENTENA")

    session.add_all([novo_animal1, novo_animal2, novo_animal3])
    session.commit()
    print("Animais inseridos com sucesso!")

    # 2. READ
    print(("\n----------READ----------"))
    print("\nListando todos os animais ordenados por nome...")
    animais_ordenados = session.execute(select(Animal).order_by(Animal.nome)).scalars().all()
    for a in animais_ordenados:
        print(f"ID: {a.id} | Nome: {a.nome} | Espécie: {a.especie} | Raça: {a.raca} | Status: {a.status}")

    # 3. UPDATE
    print(("\n----------UPDATE----------"))
    print("\nAtualizando o status do animal 'Snoopy' para 'DISPONIVEL'...")
    snoopy = session.execute(select(Animal).where(Animal.nome == "Snoopy")).scalars().first()
    if snoopy:
        snoopy.status = "DISPONIVEL"
        session.commit()
        print(f"Status do {snoopy.nome} atualizado para: {snoopy.status}")
    else:
        print(f"Animal {snoopy.nome} não encontrado.")

    # 4. DELETE
    print(("\n----------DELETE----------"))
    print("\nCriando um adotante temporário e deletando logo em seguida...")
    adotante_temp = Adotante(nome="João Deletado", cpf="00000000000", endereco="Rua Fim", idade=20, tipo_moradia="CASA", area_util_m2=50)
    session.add(adotante_temp)
    session.commit()

    # Buscando o CPF do adotante recém-criado para deletar
    alvo = session.execute(select(Adotante).where(Adotante.cpf == "00000000000")).scalars().first()
    if alvo:
        session.delete(alvo)
        session.commit()
        print(f"Adotante {alvo.nome} ({alvo.cpf}) deletado com sucesso!")
    else:
        print(f"Adotante com CPF {alvo.cpf} não encontrado.")

def executar_consultas_relacionamento(session):
    print("\n--- INICIANDO CONSULTAS COM RELACIONAMENTO ---")

    # Consulta 1: Relacionamento equivalente a JOIN (Listar Adotantes e seus Telefones)
    print(("\n----------CONSULTA 1----------"))
    print("\nJOIN 1-N: Adotantes e seus respectivos números de telefone")
    adotantes_com_telefone = session.execute(select(Adotante).join(Adotante.telefones)).scalars().unique().all()
    for adotante in adotantes_com_telefone:
        telefones_str = ", ".join([t.numero for t in adotante.telefones])
        print(f"Adotante: {adotante.nome} | Telefones: {telefones_str}")

    # Consulta 2: Relacionamento equivalente a JOIN (Listar Adoções detalhadas)
    print(("\n----------CONSULTA 2----------"))
    print("\nJOIN Múltiplo: Detalhes das Adoções realizadas")
    adocoes = session.execute(select(Adocao).join(Adocao.adotante).join(Adocao.animal)).scalars().all()
    for adocao in adocoes:
        print(f"Data: {adocao.data_adocao} | Dono: {adocao.adotante.nome} | Pet: {adocao.animal.nome} ({adocao.animal.raca}) | Taxa: R${adocao.valor_taxa}")

    # Consulta 3: Filtro + Ordenação (Animais DISPONIVEIS ordenados por idade)
    # Aqui o animal Snoopy no inicio estava como QUARENTENA, mas foi atualizado para DISPONIVEL, então ele deve aparecer na lista ordenada.
    print(("\n----------CONSULTA 3----------"))
    print("\nFiltro + Ordenação: Animais DISPONIVEIS ordenados do mais novo ao mais velho")
    animais_filtrados = session.execute(select(Animal).where(Animal.status == 'DISPONIVEL').order_by(Animal.idade_meses)).scalars().all()
    for a in animais_filtrados:
        print(f"Nome: {a.nome} | Idade: {a.idade_meses} meses | Porte: {a.porte}")

if __name__ == "__main__":
    with SessionLocal() as session:
        try:
            executar_crud(session)
            executar_consultas_relacionamento(session)
        except Exception as e:
            print(f"Erro durante a execução: {repr(e)}")
        finally:
            session.close()